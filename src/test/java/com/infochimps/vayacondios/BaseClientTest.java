package com.infochimps.vayacondios;

import java.util.Map;
import java.util.HashMap;

import junit.framework.TestCase;

public class BaseClientTest extends TestCase {

    private String organization = "vayacondios_java_integration_tests";

    public BaseClientTest(String name) {
	super(name);
    }

    public void testDefaultDryRunFalse() throws Exception {
	BaseClient client = new BaseClient(organization);
	assertFalse(client.dryRun());
    }

}
