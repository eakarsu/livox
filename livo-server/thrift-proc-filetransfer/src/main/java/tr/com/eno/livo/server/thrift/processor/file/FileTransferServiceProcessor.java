package tr.com.eno.livo.server.thrift.processor.file;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import javax.activation.MimeTypeParseException;
import org.osgi.framework.Constants;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import tr.com.eno.livo.server.file.FileTransferService;
import tr.com.eno.livo.thrift.file.FileTransferService.Iface;
import tr.com.eno.livo.thrift.file.FileTransferSession;
import tr.com.eno.livo.thrift.shared.File;

public class FileTransferServiceProcessor extends
		tr.com.eno.livo.thrift.file.FileTransferService.Processor<Iface> {

	private static final AsyncIfaceImpl iface = new AsyncIfaceImpl();
	private static final Logger LOGGER = LoggerFactory
			.getLogger(FileTransferServiceProcessor.class);

	public FileTransferServiceProcessor() {
		super(iface);

		LOGGER.debug("Initialized an {} instance.",
				FileTransferServiceProcessor.class.getSimpleName());
	}

	protected void registerService(FileTransferService service,
			Map<String, Object> serviceProps) {

		// Get the service PID
		String pid = ((String[]) serviceProps.get(Constants.SERVICE_PID))[0];

		LOGGER.debug(
				"Registering the FileTransferService instance with the name '{}'...",
				pid);

		// Register the service
		iface.registerService(pid, service);
	}

	protected void unregisterService(FileTransferService service,
			Map<String, Object> serviceProps) {

		// Get the service PID
		String pid = ((String[]) serviceProps.get(Constants.SERVICE_PID))[0];

		LOGGER.debug(
				"Unregistering the FileTransferService instance with the name '{}'...",
				pid);

		// Register the service
		iface.unregisterService(pid, service);
	}

	private static class AsyncIfaceImpl implements Iface {

		private static final int MAX_TRACKED_SESSION_ROUTES = 4096;
		private final Map<String, FileTransferService> fileTransferServices;
		private final SessionRouteRegistry sessionRoutes;

		public AsyncIfaceImpl() {

			this.fileTransferServices = new HashMap<String, FileTransferService>();
			this.sessionRoutes = new SessionRouteRegistry(MAX_TRACKED_SESSION_ROUTES);
		}

		@Override
		public void destroySession(FileTransferSession session) {

			// Find the name of the service that initiated this session
			String serviceName;
			serviceName = this.sessionRoutes.get(session.getId());

			// Sanity check
			if (serviceName == null) {

				LOGGER.warn(
						"Failed to find the service name for the file transfer session with the ID of \"{}\", ignoring the destroy request...",
						session.getId());

				return;
			}

			// Destroy the session with the appropriate service
			synchronized (this.fileTransferServices) {

				// Get the associated service
				FileTransferService service = this.fileTransferServices
						.get(serviceName);

				// Sanity check for the service
				if (service == null) {
					this.sessionRoutes.remove(session.getId());

					LOGGER.warn(
							"Failed to find a file transfer service with the name \"{}\", ignoring the destroy request...",
							serviceName);

					return;
				}

				// Try to destroy the session
				try {

					service.destroySession(this
							.convertFromThriftSession(session));

				} catch (Exception e) {

					LOGGER.debug(
							"Encountered an unexpected exception while trying to destroy the session with the ID \"{}\", ignoring the destroy request...",
							session.getId());
					LOGGER.debug("Encountered exception: {}", e);
				} finally {

					this.sessionRoutes.remove(session.getId());
				}
			}
		}

		@Override
		public ByteBuffer fetchBucket(FileTransferSession session) {

			// Find the name of the service that initiated this session
			String serviceName;
			serviceName = this.sessionRoutes.get(session.getId());

			// Sanity check
			if (serviceName == null) {

				LOGGER.warn(
						"Failed to find the service name for the file transfer session with the ID of \"{}\", ignoring the fetch request...",
						session.getId());

				return null;
			}

			synchronized (this.fileTransferServices) {

				// Get the service instance
				FileTransferService service = this.fileTransferServices
						.get(serviceName);

				// Sanity check for the service
				if (service == null) {
					this.sessionRoutes.remove(session.getId());

					LOGGER.warn(
							"Failed to find a file transfer service with the name \"{}\", ignoring the destroy request...",
							serviceName);

					return null;
				}

				// Try to get read the bucket
				try {

					ByteBuffer buffer = service.fetchBucket(this
							.convertFromThriftSession(session));
					buffer.flip();

					LOGGER.debug("Fetching the bucket {} of {}...",
							session.getCurrentIndex(), session.getBucketCount());

					if (session.getCurrentIndex() == session.getBucketCount() - 1)
						LOGGER.debug(
								"Completed the transfer of file with hash '{}'.",
								session.getFile().getHash());

					return buffer;

				} catch (Exception ex) {

					LOGGER.debug(
							"Encountered an unexpected exception while trying to destroy the session with the ID \"{}\", ignoring the destroy request...",
							session.getId());
					LOGGER.debug("Encountered exception: {}", ex);

					throw new RuntimeException(ex);
				}
			}
		}

		@Override
		public FileTransferSession initiateSession(File file, long bucketSize) {

			// Create the result session object
			FileTransferSession session = null;

			// Convert the given file object to the appropriate one
			tr.com.eno.livo.server.file.File serverFile = null;
			try {

				serverFile = this.convertFromThriftFile(file);

			} catch (MimeTypeParseException e) {

				LOGGER.warn(
						"Failed to parse the content type ({}) of the file with SHA1 hash of \"{}\"!",
						file.getContentType(), file.getHash());

				throw new RuntimeException(e);
			}

			// Try to initiate the session with file transser services
			// registered until successful
			synchronized (this.fileTransferServices) {

				for (String serviceName : this.fileTransferServices.keySet()) {

					LOGGER.debug(
							"Trying to initiate a file transfer session via the FileTransferService implementation named \"{}\" for the file with SHA1 hash of \"{}\" and with the bucket size of {}...",
							serviceName, file.getHash(), bucketSize);

					tr.com.eno.livo.server.file.FileTransferSession serverSession;

					try {

						// Try to initiate the session
						serverSession = this.fileTransferServices.get(
								serviceName).initiateSession(serverFile,
								bucketSize);

						// Convert the session object if successful
						session = this.convertToThriftSession(serverSession);

						LOGGER.debug(
								"Successfully initiated a file transfer session for file with hash '{}'.",
								file.getHash());

						// Add to the session initiated file transfer services
						this.sessionRoutes.put(session.getId(), serviceName);

						// Break the loop
						break;

					} catch (Exception ex) {

						LOGGER.debug(
								"Failed to initiate a file transfer session via the FileTransferService implementation named \"{}\" for the file with SHA1 hash of \"{}\"!",
								serviceName, file.getHash());
					}

				}
			}

			// Throw an exception if the session could not be initialized
			if (session == null) {

				LOGGER.warn(
						"None of the file transfer service implementations was able to initiate a session for the file with SHA1 hash of \"{}\"!",
						file.getHash());
			}

			// Return the session
			return session;
		}

		private tr.com.eno.livo.server.file.File convertFromThriftFile(File file)
				throws MimeTypeParseException {

			tr.com.eno.livo.server.file.File serverFile = new tr.com.eno.livo.server.file.File();
			serverFile.setContentType(file.getContentType());
			serverFile.setHash(file.getHash());
			serverFile.setPath(file.getPath());
			serverFile.setSize(file.getSize());
			return serverFile;
		}

		private tr.com.eno.livo.server.file.FileTransferSession convertFromThriftSession(
				FileTransferSession session) throws MimeTypeParseException {

			tr.com.eno.livo.server.file.FileTransferSession serverSession = new tr.com.eno.livo.server.file.FileTransferSession();
			serverSession.setId(UUID.fromString(session.getId()));
			serverSession.setBucketCount(session.getBucketCount());
			serverSession.setCurrentIndex(session.getCurrentIndex());
			serverSession
					.setFile(this.convertFromThriftFile(session.getFile()));

			return serverSession;
		}

		private File convertToThriftFile(
				tr.com.eno.livo.server.file.File serverFile) {

			File file = new File();
			if (serverFile.getContentType() != null)
				file.setContentType(serverFile.getContentType());
			file.setHash(serverFile.getHash());
			file.setPath(serverFile.getPath());
			file.setSize(serverFile.getSize());
			return file;
		}

		private FileTransferSession convertToThriftSession(
				tr.com.eno.livo.server.file.FileTransferSession serverSession) {

			FileTransferSession session = new FileTransferSession();
			session.setBucketCount(serverSession.getBucketCount());
			session.setCurrentIndex(serverSession.getCurrentIndex());
			session.setId(serverSession.getId().toString());
			session.setFile(this.convertToThriftFile(serverSession.getFile()));
			return session;
		}

		private void registerService(String name, FileTransferService service) {

			synchronized (this.fileTransferServices) {

				this.fileTransferServices.put(name, service);
			}
		}

		private void unregisterService(String name, FileTransferService service) {

			synchronized (this.fileTransferServices) {

				this.fileTransferServices.remove(name);
			}
			this.sessionRoutes.removeService(name);
		}
	}
}
