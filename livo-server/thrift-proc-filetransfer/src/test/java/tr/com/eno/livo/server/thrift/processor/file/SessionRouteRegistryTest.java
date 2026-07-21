package tr.com.eno.livo.server.thrift.processor.file;

/** Dependency-free regression coverage for bounded Thrift session routing. */
public final class SessionRouteRegistryTest {

	private SessionRouteRegistryTest() {
	}

	public static void main(String[] args) {
		SessionRouteRegistry routes = new SessionRouteRegistry(2);
		routes.put("session-1", "disk-a");
		routes.put("session-2", "disk-b");
		assertEquals("disk-a", routes.get("session-1"), "existing route should resolve");
		routes.put("session-3", "disk-c");
		assertEquals(null, routes.get("session-2"), "least-recently-used route should be evicted");
		assertEquals(2, routes.size(), "registry must remain bounded");
		routes.removeService("disk-a");
		assertEquals(null, routes.get("session-1"), "unregistered services must lose their routes");
		routes.remove("session-3");
		assertEquals(0, routes.size(), "explicit destruction must remove its route");
		System.out.println("Bounded Thrift session-route tests passed.");
	}

	private static void assertEquals(Object expected, Object actual, String message) {
		if (expected == null ? actual != null : !expected.equals(actual)) {
			throw new AssertionError(message + ": expected " + expected + " but got " + actual);
		}
	}

	private static void assertEquals(int expected, int actual, String message) {
		if (expected != actual) {
			throw new AssertionError(message + ": expected " + expected + " but got " + actual);
		}
	}
}
