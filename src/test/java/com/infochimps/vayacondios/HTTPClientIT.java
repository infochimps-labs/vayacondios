package com.infochimps.vayacondios;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Set;

import java.net.UnknownHostException;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;
import org.junit.Ignore;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;
import static org.junit.Assert.assertEquals;
import com.infochimps.vayacondios.test.IntegrationTest;
import org.junit.experimental.categories.Category;

import com.mongodb.MongoClient;
import com.mongodb.DB;

@RunWith(JUnit4.class)
@Category(IntegrationTest.class)
public class HTTPClientIT {

    private String organization = "organization";
    private String topic        = "topic";
    private String id           = "id";
    
    private HTTPClient client;

    private Map event() {
	Map e = new HashMap();
	e.put("foo", "bar");
	e.put("baz", 12.0);
	return e;
    }

    private List list() {
	List l = new ArrayList();
	l.add(1.0);
	l.add("2");
	l.add("three");
	return l;
    }

    private Map stash() {
	Map s = new HashMap();
	s.put("map", event());
	s.put("list", list());
	s.put("string", "hello");
	s.put("double", 3.1415);
	return s;
    }
    
    private Map query() {
	Map q = new HashMap();
	q.put("foo", "bar");
	return q;
    }

    @Before
    public void createClient() {
	client = new HTTPClient(organization);
    }

    @Before
    public void cleanMongo() {
	try {
	    MongoClient mongo = new MongoClient( "localhost" , 27017 );
	    DB database = mongo.getDB( "vayacondios_test" );
	    Set<String> collections = database.getCollectionNames();
	    for (String collection : collections) {
		if (! collection.matches("^system.*$")) {
		    database.getCollection(collection).drop();
		}
	    }
	} catch (UnknownHostException e) {
	    System.err.println("Could not connect to MongoDB, aborting");
	}
    } 
    
    @After
    public void closeClient() throws InterruptedException {
	client.close();
    }

    @Test
    public void canGetSetHost() {
	assertEquals(client.host(), HTTPClient.DEFAULT_HOST);
    }

    @Test
    public void canGetSetPort() {
	assertEquals(client.port(), HTTPClient.DEFAULT_PORT);
    }

    @Test
    public void eventsEmpty() {
	assertEquals(0, client.events(topic, query()).size());
    }
    
    @Test
    public void announce() {
	client.announce(topic, event());
	client.announce(topic, event());
	client.announce(topic, event());
	assertEquals(3, client.events(topic, query()).size());
    }
    
    @Test
    public void announceWithId() {
	client.announce(topic, event(), "1");
	client.announce(topic, event(), "2");
	client.announce(topic, event(), "2");
	assertEquals(2, client.events(topic, query()).size());
    }

    @Test
    public void get() {
	client.set(topic, stash());
	Map s = client.get(topic);
	assertEquals("hello", s.get("string"));
	assertEquals(3.1415, s.get("double"));
    }

    @Test
    public void getMap() {
	client.set(topic, stash());
	Map e = client.getMap(topic, "map");
	assertEquals("bar", e.get("foo"));
    }

    @Test
    public void getList() {
	client.set(topic, stash());
	List l = client.getList(topic, "list");
	assertEquals("2", l.get(1));
	assertEquals("three", l.get(2));
    }

    @Test
    public void getString() {
	client.set(topic, stash());
	String s = client.getString(topic, "string");
	assertEquals("hello", s);
    }

    @Test
    public void getDouble() {
	client.set(topic, stash());
	Double d = client.getDouble(topic, "double");
	assertEquals((Double) 3.1415, d);
    }

    @Test
    public void setOverwrites() {
	client.set(topic, stash());
	client.set(topic, event());
	Map s = client.get(topic);
	assertEquals(null, s.get("string"));
	assertEquals("bar", s.get("foo"));
    }

    @Test
    public void setWithIdMapOverwrites() {
	client.set(topic, stash());
	client.set(topic, "map", stash());
	Map s = client.getMap(topic, "map");
	assertEquals(null, s.get("foo"));
	assertEquals("hello", s.get("string"));
    }

    @Test
    public void setWithIdListOvewrites() {
	client.set(topic, stash());
	List ol = list();
	ol.set(0, "WOW");
	client.set(topic, "list", ol);
	List nl = client.getList(topic, "list");
	assertEquals("WOW", nl.get(0));
	assertEquals("2", nl.get(1));
    }

    @Test
    public void setWithIdStringOvewrites() {
	client.set(topic, stash());
	client.set(topic, "string", "goodbye");
	String s = client.getString(topic, "string");
	assertEquals("goodbye", s);
    }

    @Test
    public void setWithIdDoubleOvewrites() {
	client.set(topic, stash());
	client.set(topic, "double", 2.718);
	Double d = client.getDouble(topic, "double");
	assertEquals((double) 2.718, d, 0.001);
    }
    
    @Test
    public void mergeMerges() {
	Map s = stash();
	client.set(topic, s);
	s.put("newstring", "goodbye");
	client.set(topic, s);
	
	s = client.get(topic);
	assertEquals("hello", s.get("string"));
	assertEquals("goodbye", s.get("newstring"));
    }

    @Test
    public void mergeWithIdMapMerges() throws InterruptedException {
	client.set(topic, stash());
	Map e = new HashMap();
	e.put("bang", "boof");
	client.merge(topic, "map", e);
	Thread.sleep(100);	// need to give the server time to process the merge
	Map s = client.getMap(topic, "map");
	assertEquals("bar", s.get("foo"));
	assertEquals("boof", s.get("bang"));
    }

    public void mergeWithIdListConcatenates() throws InterruptedException {
	client.set(topic, stash());
	client.merge(topic, "list", list());
	Thread.sleep(100);	// need to give the server time to process the merge
	List l = client.getList(topic, "list");
	assertEquals(6, l.size());
    }

    public void mergeWithIdStringConcatenates() throws InterruptedException {
	client.set(topic, stash());
	client.merge(topic, "string", "goodbye");
	Thread.sleep(100);	// need to give the server time to process the merge
	String s = client.getString(topic, "string");
	assertEquals("hellogoodbye", s);
    }

    public void mergeWithIdDoubleIncrements() throws InterruptedException {
	client.set(topic, stash());
	client.merge(topic, "double", 3.1415);
	Thread.sleep(100);	// need to give the server time to process the merge
	Double d = client.getDouble(topic, "double");
	assertEquals((double) 6.2830, d, 0.001);
    }

    public void delete() throws InterruptedException {
	client.set(topic, stash());
	client.delete(topic);
	Thread.sleep(100);	// need to give the server time to process the delete
	Map s = client.get(topic);
	assertEquals(null, s);
    }

    public void deleteWithId() throws InterruptedException {
	client.set(topic, stash());
	client.delete(topic, "map");
	Thread.sleep(100);	// need to give the server time to process the delete
	Map s = client.getMap(topic, "map");
	assertEquals(null, s);
    }
    
}
