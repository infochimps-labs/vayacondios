package com.infochimps.vayacondios;

import java.util.Map;
import java.util.HashMap;

import junit.framework.TestCase;

public class HTTPClientTest extends TestCase {

    private String organization = "vayacondios_java_integration_tests";

    public HTTPClientTest(String name) {
	super(name);
    }

    private Map event() {
	HashMap e = new HashMap();
	e.put("foo", "bar");
	return e;
    }

    public void testDefaultHost() throws Exception {
	assertTrue(new HTTPClient(organization).host().equals(HTTPClient.DEFAULT_HOST));
    }

    public void testDefaultPort() throws Exception {
	assertTrue(new HTTPClient(organization).port().equals(HTTPClient.DEFAULT_PORT));
    }
    
    public void testAnnounceWithId() throws Exception {
	HTTPClient client = new HTTPClient(organization);
	client.announce("topic", event(), "1");
	client.announce("topic", event(), "2");
	client.announce("topic", event(), "3");
	Thread.sleep(5000);
	assertTrue(client.events("topic", new HashMap()).size() == 3);
    }

}
