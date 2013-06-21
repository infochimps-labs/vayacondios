package com.infochimps.vayacondios;

import java.util.Map;
import java.util.HashMap;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;
import org.junit.Ignore;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;
import static org.junit.Assert.assertEquals;

@RunWith(JUnit4.class)
public class BaseClientTest {

    private String organization = "organization";
    private String topic        = "topic";
    private String id           = "id";
    
    private BaseClient client;
    private BaseClient dryClient;

    @Before
    public void createClient() {
	client    = new BaseClient(organization);
	dryClient = new BaseClient(organization, true);
    }

    @After
    public void closeClient() throws InterruptedException {
	client.close();
    }

    @Test
    public void canGetSetOrganization() {
	assertEquals(client.organization(), organization);
    }

    @Test
    public void canGetSetDryRun() {
	assertEquals(dryClient.dryRun(), true);
    }
    
    @Test
    public void defaultDryRunFalse() {
	assertEquals(client.dryRun(), false);
    }
    
}
