package tr.com.eno.livo.server.file.disk;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.nio.file.attribute.FileTime;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import tr.com.eno.livo.server.file.File;
import tr.com.eno.livo.server.file.FileTransferSession;

/** Dependency-free regression coverage for the verified delivery workflow. */
public final class DiskFileTransferServiceWorkflowTest {

	private DiskFileTransferServiceWorkflowTest() {
	}

	public static void main(String[] args) throws Exception {
		Path root = Files.createTempDirectory("livo-file-transfer-test-");
		try {
			testVerifiedResumableDelivery(root.resolve("delivery"));
			testIdleExpiry(root.resolve("expiry"));
			System.out.println("Verified file-transfer workflow tests passed.");
		} finally {
			deleteRecursively(root);
		}
	}

	private static void testVerifiedResumableDelivery(Path root) throws Exception {
		final Path files = Files.createDirectories(root.resolve("files"));
		final Path audit = root.resolve("audit/file-transfer.log");
		byte[] content = "abcdefghijkl".getBytes(StandardCharsets.UTF_8);
		final String hash = sha256(content);
		Files.write(files.resolve(hash), content);
		Files.write(files.resolve(repeat('0', 64)), "wrong".getBytes(StandardCharsets.UTF_8));

		final DiskFileTransferService service = new DiskFileTransferService();
		service.start(configuration(files, audit, 60L));
		try {
			expect(IllegalArgumentException.class, new Action() {
				@Override
				public void run() {
					service.initiateSession(file("../outside"), 4L);
				}
			}, "path-like hashes must be rejected");
			expect(IllegalArgumentException.class, new Action() {
				@Override
				public void run() {
					service.initiateSession(file(hash), 0L);
				}
			}, "zero-byte buckets must be rejected");
			expect(IllegalArgumentException.class, new Action() {
				@Override
				public void run() {
					service.initiateSession(file(hash), 1025L);
				}
			}, "oversized buckets must be rejected");
			expect(SecurityException.class, new Action() {
				@Override
				public void run() {
					service.initiateSession(file(repeat('0', 64)), 4L);
				}
			}, "digest mismatches must fail closed");

			final FileTransferSession session = service.initiateSession(file(hash), 4L);
			assertEquals(3L, session.getBucketCount(), "exact multiples must not create an empty trailing bucket");
			assertEquals(content.length, session.getFile().getSize(), "server must report authoritative file size");
			expect(IllegalStateException.class, new Action() {
				@Override
				public void run() {
					service.initiateSession(file(hash), 4L);
				}
			}, "active sessions must be bounded");

			// Mutating the client's copy must not redirect an established session.
			session.getFile().setHash(repeat('0', 64));
			byte[] first = bytes(service.fetchBucket(session));
			assertArrayEquals("abcd".getBytes(StandardCharsets.UTF_8), first,
					"first bucket should come from the authoritative file");
			assertArrayEquals(first, bytes(service.fetchBucket(session)),
					"the immediately preceding bucket should be replayable");

			session.setCurrentIndex(2L);
			expect(IllegalStateException.class, new Action() {
				@Override
				public void run() {
					service.fetchBucket(session);
				}
			}, "skipping a bucket must be rejected");

			ByteArrayOutputStream reconstructed = new ByteArrayOutputStream();
			reconstructed.write(first);
			session.setCurrentIndex(1L);
			reconstructed.write(bytes(service.fetchBucket(session)));
			session.setCurrentIndex(2L);
			reconstructed.write(bytes(service.fetchBucket(session)));
			assertArrayEquals(content, reconstructed.toByteArray(),
					"ordered buckets must reconstruct the verified source");

			new FileTransferAuditLog(audit).verify();
			service.destroySession(session);
			expect(IllegalStateException.class, new Action() {
				@Override
				public void run() {
					service.fetchBucket(session);
				}
			}, "destroyed sessions must be unusable");

			byte[] mutableContent = "mutable0".getBytes(StandardCharsets.UTF_8);
			final String mutableHash = sha256(mutableContent);
			final Path mutablePath = files.resolve(mutableHash);
			Files.write(mutablePath, mutableContent);
			final FileTransferSession mutableSession = service.initiateSession(file(mutableHash), 4L);
			long originalModified = Files.getLastModifiedTime(mutablePath).toMillis();
			Files.write(mutablePath, "changed!".getBytes(StandardCharsets.UTF_8));
			Files.setLastModifiedTime(mutablePath, FileTime.fromMillis(originalModified + 2000L));
			expect(SecurityException.class, new Action() {
				@Override
				public void run() {
					service.fetchBucket(mutableSession);
				}
			}, "content changed during a session must be rejected");
			service.destroySession(mutableSession);
		} finally {
			service.stop();
		}

		String auditText = new String(Files.readAllBytes(audit), StandardCharsets.UTF_8);
		Files.write(audit, auditText.replace("SESSION_STARTED", "SESSION_XTARTED")
				.getBytes(StandardCharsets.UTF_8));
		final DiskFileTransferService restarted = new DiskFileTransferService();
		expect(SecurityException.class, new Action() {
			@Override
			public void run() {
				restarted.start(configuration(files, audit, 60L));
			}
		}, "tampered audit records must prevent startup");
	}

	private static void testIdleExpiry(Path root) throws Exception {
		Path files = Files.createDirectories(root.resolve("files"));
		Path audit = root.resolve("audit/file-transfer.log");
		byte[] content = "expiry".getBytes(StandardCharsets.UTF_8);
		String hash = sha256(content);
		Files.write(files.resolve(hash), content);

		final DiskFileTransferService service = new DiskFileTransferService();
		service.start(configuration(files, audit, 1L));
		try {
			final FileTransferSession session = service.initiateSession(file(hash), 3L);
			Thread.sleep(1100L);
			expect(IllegalStateException.class, new Action() {
				@Override
				public void run() {
					service.fetchBucket(session);
				}
			}, "idle sessions must expire");
		} finally {
			service.stop();
		}
		new FileTransferAuditLog(audit).verify();
	}

	private static byte[] bytes(ByteBuffer buffer) {
		buffer.flip();
		byte[] result = new byte[buffer.remaining()];
		buffer.get(result);
		return result;
	}

	private static Map<String, Object> configuration(Path files, Path audit, long ttlSeconds) {
		Map<String, Object> config = new HashMap<String, Object>();
		config.put(DiskFileTransferService.CONFIG_FILES_DIRECTORY, files.toString());
		config.put(DiskFileTransferService.CONFIG_AUDIT_FILE, audit.toString());
		config.put(DiskFileTransferService.CONFIG_MAX_ACTIVE_SESSIONS, "1");
		config.put(DiskFileTransferService.CONFIG_MAX_BUCKET_BYTES, "1024");
		config.put(DiskFileTransferService.CONFIG_SESSION_TTL_SECONDS, Long.toString(ttlSeconds));
		return config;
	}

	private static void deleteRecursively(Path root) throws IOException {
		if (!Files.exists(root)) {
			return;
		}
		Files.walkFileTree(root, new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attributes)
					throws IOException {
				Files.delete(file);
				return FileVisitResult.CONTINUE;
			}

			@Override
			public FileVisitResult postVisitDirectory(Path directory, IOException failure)
					throws IOException {
				if (failure != null) {
					throw failure;
				}
				Files.delete(directory);
				return FileVisitResult.CONTINUE;
			}
		});
	}

	private static File file(String hash) {
		File file = new File();
		file.setHash(hash);
		file.setContentType("application/octet-stream");
		file.setPath("download.bin");
		return file;
	}

	private static String repeat(char value, int count) {
		char[] result = new char[count];
		Arrays.fill(result, value);
		return new String(result);
	}

	private static String sha256(byte[] content) throws Exception {
		byte[] digest = MessageDigest.getInstance("SHA-256").digest(content);
		StringBuilder result = new StringBuilder(digest.length * 2);
		for (byte value : digest) {
			result.append(String.format(Locale.US, "%02x", value & 0xff));
		}
		return result.toString();
	}

	private static void assertArrayEquals(byte[] expected, byte[] actual, String message) {
		if (!Arrays.equals(expected, actual)) {
			throw new AssertionError(message);
		}
	}

	private static void assertEquals(long expected, long actual, String message) {
		if (expected != actual) {
			throw new AssertionError(message + ": expected " + expected + " but got " + actual);
		}
	}

	private static void expect(Class<? extends Throwable> type, Action action, String message) {
		try {
			action.run();
		} catch (Throwable failure) {
			if (type.isInstance(failure)) {
				return;
			}
			throw new AssertionError(message + ": wrong exception " + failure, failure);
		}
		throw new AssertionError(message + ": no exception was thrown");
	}

	private interface Action {
		void run() throws Exception;
	}
}
