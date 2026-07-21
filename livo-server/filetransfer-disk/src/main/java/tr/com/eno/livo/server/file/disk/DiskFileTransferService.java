package tr.com.eno.livo.server.file.disk;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import tr.com.eno.livo.server.file.File;
import tr.com.eno.livo.server.file.FileTransferService;
import tr.com.eno.livo.server.file.FileTransferSession;

/**
 * Disk-backed delivery of files from an immutable, content-addressed store.
 *
 * <p>The public SPI uses mutable transfer sessions. This implementation treats
 * the session ID as the only client-controlled capability and keeps the file,
 * bucket size, and cursor authoritative on the server. A caller may request the
 * next bucket or replay the immediately preceding bucket for a safe retry.</p>
 */
public class DiskFileTransferService implements FileTransferService {

	static final String CONFIG_AUDIT_FILE = "audit.file";
	static final String CONFIG_FILES_DIRECTORY = "file.storage";
	static final String CONFIG_MAX_ACTIVE_SESSIONS = "max.active.sessions";
	static final String CONFIG_MAX_BUCKET_BYTES = "max.bucket.bytes";
	static final String CONFIG_SESSION_TTL_SECONDS = "session.ttl.seconds";

	private static final String ENV_AUDIT_FILE = "LIVO_FILE_TRANSFER_AUDIT";
	private static final String ENV_FILES_DIRECTORY = "LIVO_FILE_STORAGE";
	private static final String ENV_MAX_ACTIVE_SESSIONS = "LIVO_FILE_TRANSFER_MAX_ACTIVE_SESSIONS";
	private static final String ENV_MAX_BUCKET_BYTES = "LIVO_FILE_TRANSFER_MAX_BUCKET_BYTES";
	private static final String ENV_SESSION_TTL_SECONDS = "LIVO_FILE_TRANSFER_SESSION_TTL_SECONDS";
	private static final String FILES_PATH = "files";
	private static final String AUDIT_PATH = "audit/file-transfer.log";
	private static final long DEFAULT_MAX_ACTIVE_SESSIONS = 256L;
	private static final long DEFAULT_MAX_BUCKET_BYTES = 8L * 1024L * 1024L;
	private static final long DEFAULT_SESSION_TTL_SECONDS = 300L;
	private static final Pattern CONTENT_HASH = Pattern.compile("(?i)([0-9a-f]{40}|[0-9a-f]{64})");
	private static final Logger LOGGER = LoggerFactory.getLogger(DiskFileTransferService.class);

	private final Object sessionLock = new Object();
	private final Map<UUID, SessionState> sessions = new HashMap<UUID, SessionState>();

	private java.io.File filesDirectory;
	private FileTransferAuditLog auditLog;
	private int maxActiveSessions;
	private long maxBucketBytes;
	private volatile boolean running;
	private long sessionTtlMillis;

	@Override
	public void destroySession(FileTransferSession requestedSession) {
		ensureStarted();
		if (requestedSession == null || requestedSession.getId() == null) {
			throw new IllegalArgumentException("A transfer session ID is required.");
		}

		SessionState state;
		synchronized (sessionLock) {
			state = sessions.remove(requestedSession.getId());
		}
		if (state == null) {
			return;
		}

		RuntimeException auditFailure = null;
		synchronized (state) {
			try {
				auditLog.append("SESSION_DESTROYED", state.session.getId(),
						state.session.getFile().getHash(), state.nextIndex);
			} catch (RuntimeException e) {
				auditFailure = e;
			} finally {
				closeQuietly(state.channel);
			}
		}
		if (auditFailure != null) {
			throw auditFailure;
		}
	}

	@Override
	public ByteBuffer fetchBucket(FileTransferSession requestedSession) {
		ensureStarted();
		if (requestedSession == null || requestedSession.getId() == null) {
			throw new IllegalArgumentException("A transfer session ID is required.");
		}
		if (requestedSession.getCurrentIndex() < 0L) {
			throw new IllegalArgumentException("Bucket index cannot be negative.");
		}

		removeExpiredSessions();
		SessionState state;
		synchronized (sessionLock) {
			state = sessions.get(requestedSession.getId());
		}
		if (state == null) {
			throw new IllegalStateException("Transfer session is unknown or expired.");
		}

		synchronized (state) {
			long now = System.currentTimeMillis();
			if (state.expiresAtMillis <= now) {
				expireSession(state);
				throw new IllegalStateException("Transfer session has expired.");
			}

			long requestedIndex = requestedSession.getCurrentIndex();
			if (requestedIndex == state.lastIndex && state.lastIndex >= 0L) {
				ensureStoredFileUnchanged(state);
				byte[] replayedBucket = readBucket(state, requestedIndex);
				auditLog.append("BUCKET_REPLAYED", state.session.getId(),
						state.session.getFile().getHash(), requestedIndex);
				state.expiresAtMillis = safeAdd(System.currentTimeMillis(), sessionTtlMillis);
				return bufferAtEnd(replayedBucket);
			}
			if (requestedIndex != state.nextIndex) {
				throw new IllegalStateException("Expected bucket " + state.nextIndex
						+ " but received " + requestedIndex + ".");
			}
			if (requestedIndex >= state.session.getBucketCount()) {
				throw new IllegalStateException("All buckets have already been delivered.");
			}

			ensureStoredFileUnchanged(state);
			byte[] bucket = readBucket(state, requestedIndex);
			boolean completesTransfer = requestedIndex + 1L == state.session.getBucketCount();
			auditLog.append(completesTransfer ? "TRANSFER_COMPLETED" : "BUCKET_SERVED",
					state.session.getId(),
					state.session.getFile().getHash(), requestedIndex);
			state.lastIndex = requestedIndex;
			state.nextIndex++;
			state.expiresAtMillis = safeAdd(System.currentTimeMillis(), sessionTtlMillis);

			return bufferAtEnd(bucket);
		}
	}

	@Override
	public synchronized FileTransferSession initiateSession(File requested, long bucketSize) {
		ensureStarted();
		removeExpiredSessions();
		if (requested == null || requested.getHash() == null
				|| !CONTENT_HASH.matcher(requested.getHash()).matches()) {
			throw new IllegalArgumentException("File hash must be a 40-character SHA-1 or 64-character SHA-256 value.");
		}
		if (bucketSize <= 0L || bucketSize > maxBucketBytes
				|| bucketSize > Integer.MAX_VALUE) {
			throw new IllegalArgumentException("Bucket size must be between 1 and "
					+ maxBucketBytes + " bytes.");
		}
		synchronized (sessionLock) {
			if (sessions.size() >= maxActiveSessions) {
				throw new IllegalStateException("The active file-transfer session limit has been reached.");
			}
		}

		String normalizedHash = requested.getHash().toLowerCase(Locale.US);
		Path root = filesDirectory.toPath();
		Path storedPath = root.resolve(normalizedHash).normalize();
		if (!storedPath.getParent().equals(root)
				|| Files.isSymbolicLink(storedPath)
				|| !Files.isRegularFile(storedPath, LinkOption.NOFOLLOW_LINKS)) {
			throw new RuntimeException(new FileNotFoundException("Content-addressed file is unavailable."));
		}

		FileChannel channel = null;
		try {
			channel = FileChannel.open(storedPath, StandardOpenOption.READ,
					LinkOption.NOFOLLOW_LINKS);
			long sizeBefore = channel.size();
			long modifiedBefore = Files.getLastModifiedTime(storedPath,
					LinkOption.NOFOLLOW_LINKS).toMillis();
			String actualHash = digest(channel, normalizedHash.length() == 40 ? "SHA-1" : "SHA-256");
			long sizeAfter = channel.size();
			long modifiedAfter = Files.getLastModifiedTime(storedPath,
					LinkOption.NOFOLLOW_LINKS).toMillis();
			if (sizeBefore != sizeAfter || modifiedBefore != modifiedAfter
					|| !normalizedHash.equals(actualHash)) {
				throw new SecurityException("Stored content does not match its content-addressed filename.");
			}

			File authoritativeFile = copyFile(requested);
			authoritativeFile.setHash(normalizedHash);
			authoritativeFile.setSize(sizeAfter);
			FileTransferSession authoritativeSession = new FileTransferSession();
			authoritativeSession.setId(nextSessionId());
			authoritativeSession.setFile(authoritativeFile);
			authoritativeSession.setBucketCount(bucketCount(sizeAfter, bucketSize));
			authoritativeSession.setCurrentIndex(0L);

			SessionState state = new SessionState(authoritativeSession, channel,
					bucketSize, sizeAfter, modifiedAfter,
					safeAdd(System.currentTimeMillis(), sessionTtlMillis), storedPath);
			auditLog.append("SESSION_STARTED", authoritativeSession.getId(),
					normalizedHash, -1L);
			synchronized (sessionLock) {
				sessions.put(authoritativeSession.getId(), state);
			}
			channel = null;
			return copySession(authoritativeSession);
		} catch (IOException e) {
			throw new RuntimeException("Unable to open content-addressed file.", e);
		} finally {
			closeQuietly(channel);
		}
	}

	protected synchronized void start(Map<String, Object> config) {
		LOGGER.info("Starting disk-backed file transfer service...");
		if (running) {
			throw new IllegalStateException("Disk file transfer service is already running.");
		}

		String homePath = trimToNull(System.getenv("AEON_HOME"));
		String configuredFiles = setting(config, CONFIG_FILES_DIRECTORY,
				ENV_FILES_DIRECTORY, homePath == null ? null
						: new java.io.File(homePath, FILES_PATH).getPath());
		String configuredAudit = setting(config, CONFIG_AUDIT_FILE,
				ENV_AUDIT_FILE, homePath == null ? null
						: new java.io.File(homePath, AUDIT_PATH).getPath());
		if (configuredFiles == null || configuredAudit == null) {
			throw new IllegalStateException("Set AEON_HOME or configure both file.storage and audit.file.");
		}

		maxBucketBytes = positiveSetting(config, CONFIG_MAX_BUCKET_BYTES,
				ENV_MAX_BUCKET_BYTES, DEFAULT_MAX_BUCKET_BYTES);
		long configuredMaxSessions = positiveSetting(config,
				CONFIG_MAX_ACTIVE_SESSIONS, ENV_MAX_ACTIVE_SESSIONS,
				DEFAULT_MAX_ACTIVE_SESSIONS);
		if (configuredMaxSessions > Integer.MAX_VALUE) {
			throw new IllegalArgumentException("Active session limit is too large.");
		}
		maxActiveSessions = (int) configuredMaxSessions;
		long ttlSeconds = positiveSetting(config, CONFIG_SESSION_TTL_SECONDS,
				ENV_SESSION_TTL_SECONDS, DEFAULT_SESSION_TTL_SECONDS);
		if (ttlSeconds > Long.MAX_VALUE / 1000L) {
			throw new IllegalArgumentException("Session TTL is too large.");
		}
		sessionTtlMillis = ttlSeconds * 1000L;

		try {
			Path configuredRoot = new java.io.File(configuredFiles).toPath().toAbsolutePath();
			if (Files.exists(configuredRoot, LinkOption.NOFOLLOW_LINKS)
					&& Files.isSymbolicLink(configuredRoot)) {
				throw new SecurityException("The content store may not be a symbolic link.");
			}
			Files.createDirectories(configuredRoot);
			if (!Files.isDirectory(configuredRoot, LinkOption.NOFOLLOW_LINKS)) {
				throw new IllegalStateException("Configured content store is not a directory.");
			}
			filesDirectory = configuredRoot.toFile().getCanonicalFile();
			auditLog = new FileTransferAuditLog(new java.io.File(configuredAudit).toPath());
			auditLog.verify();
		} catch (IOException e) {
			throw new RuntimeException("Unable to initialize disk file transfer storage.", e);
		}
		running = true;
		LOGGER.info("Disk-backed file transfer service started with a {} session limit, {} byte bucket limit, and {} second idle TTL.",
				maxActiveSessions, maxBucketBytes, ttlSeconds);
	}

	protected synchronized void reconfigure(Map<String, Object> config) {
		stop();
		start(config);
	}

	protected synchronized void stop() {
		LOGGER.info("Stopping the disk-backed file transfer service...");
		running = false;
		List<SessionState> openSessions;
		synchronized (sessionLock) {
			openSessions = new ArrayList<SessionState>(sessions.values());
			sessions.clear();
		}
		for (SessionState state : openSessions) {
			synchronized (state) {
				closeQuietly(state.channel);
			}
		}
		LOGGER.info("Disk-backed file transfer service stopped.");
	}

	private long bucketCount(long fileSize, long bucketSize) {
		if (fileSize == 0L) {
			return 1L;
		}
		return fileSize / bucketSize + (fileSize % bucketSize == 0L ? 0L : 1L);
	}

	private ByteBuffer bufferAtEnd(byte[] bytes) {
		ByteBuffer buffer = ByteBuffer.allocate(bytes.length);
		buffer.put(bytes);
		return buffer;
	}

	private void closeQuietly(FileChannel channel) {
		if (channel == null) {
			return;
		}
		try {
			channel.close();
		} catch (IOException e) {
			LOGGER.warn("Unable to close a file-transfer channel.", e);
		}
	}

	private File copyFile(File source) {
		File copy = new File();
		copy.setContentType(source.getContentType());
		copy.setHash(source.getHash());
		copy.setPath(source.getPath());
		copy.setSize(source.getSize());
		return copy;
	}

	private FileTransferSession copySession(FileTransferSession source) {
		FileTransferSession copy = new FileTransferSession();
		copy.setId(source.getId());
		copy.setFile(copyFile(source.getFile()));
		copy.setBucketCount(source.getBucketCount());
		copy.setCurrentIndex(source.getCurrentIndex());
		return copy;
	}

	private String digest(FileChannel channel, String algorithm) throws IOException {
		try {
			MessageDigest digest = MessageDigest.getInstance(algorithm);
			ByteBuffer buffer = ByteBuffer.allocate(64 * 1024);
			long position = 0L;
			while (true) {
				buffer.clear();
				int read = channel.read(buffer, position);
				if (read < 0) {
					break;
				}
				if (read == 0) {
					continue;
				}
				position += read;
				digest.update(buffer.array(), 0, read);
			}
			return toHex(digest.digest());
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalStateException("Required content digest is unavailable.", e);
		}
	}

	private void ensureStarted() {
		if (!running) {
			throw new IllegalStateException("Disk file transfer service is not running.");
		}
	}

	private void ensureStoredFileUnchanged(SessionState state) {
		try {
			if (Files.isSymbolicLink(state.path)
					|| !Files.isRegularFile(state.path, LinkOption.NOFOLLOW_LINKS)
					|| state.channel.size() != state.fileSize
					|| Files.getLastModifiedTime(state.path,
							LinkOption.NOFOLLOW_LINKS).toMillis() != state.lastModifiedMillis) {
				throw new SecurityException("Content-addressed file changed during transfer.");
			}
		} catch (IOException e) {
			throw new RuntimeException("Unable to validate content-addressed file.", e);
		}
	}

	private void expireSession(SessionState state) {
		boolean removed;
		synchronized (sessionLock) {
			removed = sessions.remove(state.session.getId()) != null;
		}
		if (removed) {
			try {
				auditLog.append("SESSION_EXPIRED", state.session.getId(),
						state.session.getFile().getHash(), state.nextIndex);
			} finally {
				closeQuietly(state.channel);
			}
		}
	}

	private UUID nextSessionId() {
		UUID id = UUID.randomUUID();
		synchronized (sessionLock) {
			while (sessions.containsKey(id)) {
				id = UUID.randomUUID();
			}
		}
		return id;
	}

	private long positiveSetting(Map<String, Object> config, String configKey,
			String environmentKey, long defaultValue) {
		String value = setting(config, configKey, environmentKey,
				Long.toString(defaultValue));
		try {
			long parsed = Long.parseLong(value);
			if (parsed <= 0L) {
				throw new NumberFormatException("not positive");
			}
			return parsed;
		} catch (NumberFormatException e) {
			throw new IllegalArgumentException(configKey + " must be a positive integer.", e);
		}
	}

	private byte[] readBucket(SessionState state, long index) {
		if (index != 0L && state.bucketSize > Long.MAX_VALUE / index) {
			throw new IllegalStateException("Bucket offset overflow.");
		}
		long offset = index * state.bucketSize;
		int expected = (int) Math.min(state.bucketSize, state.fileSize - offset);
		ByteBuffer target = ByteBuffer.allocate(expected);
		long position = offset;
		try {
			while (target.hasRemaining()) {
				int read = state.channel.read(target, position);
				if (read < 0) {
					throw new IOException("Unexpected end of content-addressed file.");
				}
				if (read == 0) {
					continue;
				}
				position += read;
			}
			return target.array();
		} catch (IOException e) {
			throw new RuntimeException("Unable to read requested file bucket.", e);
		}
	}

	private void removeExpiredSessions() {
		long now = System.currentTimeMillis();
		List<SessionState> expired = new ArrayList<SessionState>();
		synchronized (sessionLock) {
			for (SessionState state : sessions.values()) {
				if (state.expiresAtMillis <= now) {
					expired.add(state);
				}
			}
		}
		for (SessionState state : expired) {
			synchronized (state) {
				if (state.expiresAtMillis <= System.currentTimeMillis()) {
					expireSession(state);
				}
			}
		}
	}

	private long safeAdd(long left, long right) {
		return left > Long.MAX_VALUE - right ? Long.MAX_VALUE : left + right;
	}

	private String setting(Map<String, Object> config, String configKey,
			String environmentKey, String defaultValue) {
		if (config != null && config.get(configKey) != null) {
			String configured = trimToNull(String.valueOf(config.get(configKey)));
			if (configured != null) {
				return configured;
			}
		}
		String environment = trimToNull(System.getenv(environmentKey));
		return environment == null ? defaultValue : environment;
	}

	private String toHex(byte[] bytes) {
		StringBuilder result = new StringBuilder(bytes.length * 2);
		for (byte value : bytes) {
			result.append(String.format(Locale.US, "%02x", value & 0xff));
		}
		return result.toString();
	}

	private String trimToNull(String value) {
		if (value == null) {
			return null;
		}
		String trimmed = value.trim();
		return trimmed.length() == 0 ? null : trimmed;
	}

	private static final class SessionState {
		private final FileChannel channel;
		private volatile long expiresAtMillis;
		private final long fileSize;
		private final long lastModifiedMillis;
		private final long bucketSize;
		private long lastIndex = -1L;
		private long nextIndex = 0L;
		private final Path path;
		private final FileTransferSession session;

		private SessionState(FileTransferSession session, FileChannel channel,
				long bucketSize, long fileSize, long lastModifiedMillis,
				long expiresAtMillis, Path path) {
			this.session = session;
			this.channel = channel;
			this.bucketSize = bucketSize;
			this.fileSize = fileSize;
			this.lastModifiedMillis = lastModifiedMillis;
			this.expiresAtMillis = expiresAtMillis;
			this.path = path;
		}
	}
}
