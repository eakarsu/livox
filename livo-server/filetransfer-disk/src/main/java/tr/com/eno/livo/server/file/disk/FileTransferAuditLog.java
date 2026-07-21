package tr.com.eno.livo.server.file.disk;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.PosixFilePermission;
import java.nio.file.attribute.PosixFilePermissions;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/** A small local hash chain for file-delivery audit evidence. */
final class FileTransferAuditLog {

	private static final long MAX_AUDIT_BYTES = 64L * 1024L * 1024L;
	private static final String ZERO_HASH = "0000000000000000000000000000000000000000000000000000000000000000";
	private final Path path;

	FileTransferAuditLog(Path path) throws IOException {
		this.path = path.toAbsolutePath().normalize();
		Path parent = this.path.getParent();
		if (parent == null) {
			throw new IllegalArgumentException("Audit file must have a parent directory.");
		}
		if (Files.exists(this.path, LinkOption.NOFOLLOW_LINKS)
				&& Files.isSymbolicLink(this.path)) {
			throw new SecurityException("Audit file may not be a symbolic link.");
		}
		boolean createPrivateParent = !Files.exists(parent, LinkOption.NOFOLLOW_LINKS);
		Files.createDirectories(parent);
		if (Files.isSymbolicLink(parent)
				|| !Files.isDirectory(parent, LinkOption.NOFOLLOW_LINKS)) {
			throw new SecurityException("Audit parent must be a regular directory, not a symbolic link.");
		}
		if (createPrivateParent) {
			trySetPermissions(parent, PosixFilePermissions.fromString("rwx------"));
		}
		if (!Files.exists(this.path, LinkOption.NOFOLLOW_LINKS)) {
			Files.createFile(this.path);
		}
		if (!Files.isRegularFile(this.path, LinkOption.NOFOLLOW_LINKS)) {
			throw new IllegalArgumentException("Audit path is not a regular file.");
		}
		trySetPermissions(this.path, PosixFilePermissions.fromString("rw-------"));
	}

	synchronized void append(String event, UUID sessionId, String fileHash, long bucketIndex) {
		String safeEvent = requiredToken(event, "event");
		String safeSession = requiredToken(sessionId == null ? "NONE" : sessionId.toString(), "session ID");
		String safeHash = requiredToken(fileHash == null ? "NONE" : fileHash, "file hash");
		try (FileChannel channel = FileChannel.open(path, StandardOpenOption.READ,
				StandardOpenOption.WRITE, LinkOption.NOFOLLOW_LINKS);
				FileLock lock = channel.lock()) {
			if (!lock.isValid()) {
				throw new IllegalStateException("Unable to acquire the file-transfer audit lock.");
			}
			byte[] existing = read(channel);
			String previousHash = verify(existing);
			String payload = "1|" + System.currentTimeMillis() + "|" + safeEvent
					+ "|" + safeSession + "|" + safeHash + "|" + bucketIndex
					+ "|" + previousHash;
			String line = payload + "|" + sha256(payload) + "\n";
			channel.position(channel.size());
			ByteBuffer bytes = ByteBuffer.wrap(line.getBytes(StandardCharsets.UTF_8));
			while (bytes.hasRemaining()) {
				channel.write(bytes);
			}
			channel.force(true);
		} catch (IOException e) {
			throw new IllegalStateException("Unable to append file-transfer audit event.", e);
		}
	}

	void verify() {
		try (FileChannel channel = FileChannel.open(path, StandardOpenOption.READ,
				StandardOpenOption.WRITE, LinkOption.NOFOLLOW_LINKS);
				FileLock lock = channel.lock()) {
			if (!lock.isValid()) {
				throw new IllegalStateException("Unable to acquire the file-transfer audit lock.");
			}
			verify(read(channel));
		} catch (IOException e) {
			throw new IllegalStateException("Unable to verify file-transfer audit log.", e);
		}
	}

	private byte[] read(FileChannel channel) throws IOException {
		long size = channel.size();
		if (size > MAX_AUDIT_BYTES) {
			throw new IllegalStateException("Local audit log exceeds 64 MiB; archive it through an approved audit process.");
		}
		channel.position(0L);
		ByteArrayOutputStream output = new ByteArrayOutputStream((int) size);
		ByteBuffer buffer = ByteBuffer.allocate(8192);
		while (true) {
			buffer.clear();
			int count = channel.read(buffer);
			if (count < 0) {
				break;
			}
			if (count == 0) {
				continue;
			}
			output.write(buffer.array(), 0, count);
		}
		return output.toByteArray();
	}

	private String requiredToken(String value, String label) {
		if (value.length() == 0 || value.indexOf('|') >= 0
				|| value.indexOf('\n') >= 0 || value.indexOf('\r') >= 0) {
			throw new IllegalArgumentException("Invalid audit " + label + ".");
		}
		return value;
	}

	private String sha256(String value) {
		try {
			MessageDigest digest = MessageDigest.getInstance("SHA-256");
			byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
			StringBuilder result = new StringBuilder(hash.length * 2);
			for (byte item : hash) {
				result.append(String.format(Locale.US, "%02x", item & 0xff));
			}
			return result.toString();
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalStateException("SHA-256 is unavailable.", e);
		}
	}

	private void trySetPermissions(Path target, Set<PosixFilePermission> permissions) {
		try {
			Files.setPosixFilePermissions(target, permissions);
		} catch (UnsupportedOperationException e) {
			// The platform does not expose POSIX permissions (for example, Windows).
		} catch (IOException e) {
			throw new IllegalStateException("Unable to restrict audit permissions for " + target + ".", e);
		}
	}

	private String verify(byte[] content) {
		if (content.length == 0) {
			return ZERO_HASH;
		}
		String text = new String(content, StandardCharsets.UTF_8);
		if (!text.endsWith("\n")) {
			throw new SecurityException("File-transfer audit log has an incomplete record.");
		}
		String previous = ZERO_HASH;
		String[] lines = text.split("\n", -1);
		for (int index = 0; index < lines.length - 1; index++) {
			String[] fields = lines[index].split("\\|", -1);
			if (fields.length != 8 || !"1".equals(fields[0])
					|| !previous.equals(fields[6])) {
				throw new SecurityException("File-transfer audit chain is invalid at record " + (index + 1) + ".");
			}
			String payload = fields[0] + "|" + fields[1] + "|" + fields[2]
					+ "|" + fields[3] + "|" + fields[4] + "|" + fields[5]
					+ "|" + fields[6];
			if (!sha256(payload).equals(fields[7])) {
				throw new SecurityException("File-transfer audit record hash is invalid at record " + (index + 1) + ".");
			}
			previous = fields[7];
		}
		return previous;
	}
}
