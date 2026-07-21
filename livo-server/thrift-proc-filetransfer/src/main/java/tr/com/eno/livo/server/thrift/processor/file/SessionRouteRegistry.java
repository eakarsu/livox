package tr.com.eno.livo.server.thrift.processor.file;

import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

/** Thread-safe, access-ordered routing state with an explicit memory bound. */
final class SessionRouteRegistry {

	private final int maximumSize;
	private final LinkedHashMap<String, String> routes;

	SessionRouteRegistry(int maximumSize) {
		if (maximumSize <= 0) {
			throw new IllegalArgumentException("Maximum route count must be positive.");
		}
		this.maximumSize = maximumSize;
		this.routes = new LinkedHashMap<String, String>(16, 0.75f, true);
	}

	synchronized String get(String sessionId) {
		return sessionId == null ? null : routes.get(sessionId);
	}

	synchronized void put(String sessionId, String serviceName) {
		if (sessionId == null || serviceName == null) {
			throw new IllegalArgumentException("Session ID and service name are required.");
		}
		routes.put(sessionId, serviceName);
		while (routes.size() > maximumSize) {
			Iterator<String> oldest = routes.keySet().iterator();
			oldest.next();
			oldest.remove();
		}
	}

	synchronized void remove(String sessionId) {
		if (sessionId != null) {
			routes.remove(sessionId);
		}
	}

	synchronized void removeService(String serviceName) {
		Iterator<Map.Entry<String, String>> iterator = routes.entrySet().iterator();
		while (iterator.hasNext()) {
			if (serviceName.equals(iterator.next().getValue())) {
				iterator.remove();
			}
		}
	}

	synchronized int size() {
		return routes.size();
	}
}
