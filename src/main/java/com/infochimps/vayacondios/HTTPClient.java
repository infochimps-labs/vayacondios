package com.infochimps.vayacondios;

import java.util.Map;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.ArrayUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.http.client.methods.HttpEntityEnclosingRequestBase;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.HttpResponse;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.client.BasicResponseHandler;

import com.ning.http.client.AsyncHttpClient;
import com.ning.http.client.AsyncCompletionHandler;
import com.ning.http.client.Response;
import java.util.concurrent.Future;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonParseException;

/** A Vayacondios client which communicates with the Vayacondios
 * server via HTTP requests.
 *
 * Requests which write data to the Vayacondios server are implemented
 * via asynchronous (non-blocking) calls which with return type
 * <code>void</code>.These include:
 *
 * <ul>
 *   <li>announce</li>
 *   <li>set</li>
 *   <li>merge</li>
 *   <li>delete</li>
 * </ul>
 *
 * Requests which read data from the Vayacondios server are
 * implemented via synchronous (blocking) calls which return an
 * expected Java type.  These include:
 * 
 * <ul>
 *   <li>events</li>
 *   <li>stashes</li>
 *   <li>get, getMap, getList, getString, getDouble</li>
 * </ul>
 *
 * Each Vayacondios HTTPClient instance exposes two HTTP client objects:
 * 
 * <ul>
 *   <li>{@link #asynchronousClient()} which returns an AsyncHttpClient from the <a href="https://github.com/AsyncHttpClient/async-http-client">AsyncHttpClient</a></li> library
 *   <li>{@link #synchronousClient()} which returns a <code>Defaulthttpclient</code> from the <a href="http://hc.apache.org/httpclient-3.x/">Apache commons HttpClient</a> library
 * </ul>
 *
 * You can use these objects directly to do make raw HTTP requests
 * against the Vayacondios server in whichever mode you prefer.
 * 
 */
public class HTTPClient extends BaseClient {

    private class HttpGetWithBody extends HttpEntityEnclosingRequestBase {
	
	public final static String METHOD_NAME = "GET";

	HttpGetWithBody(String uri, String body) throws URISyntaxException, UnsupportedEncodingException {
	    setURI(new URI(uri));
	    setEntity(new StringEntity(body));
	}
	
	@Override
	public String getMethod() {
	    return METHOD_NAME;
	}
    }

    private class AsyncResponseHandler extends AsyncCompletionHandler {
	@Override
	public Response onCompleted(Response response) throws Exception {
	    return response;
	}
    }
    
    //----------------------------------------------------------------------------
    // Initialization & Properties
    //----------------------------------------------------------------------------

    private static Logger LOG = LoggerFactory.getLogger(HTTPClient.class);
    
    /** Default Vayacondios server host. */
    public static String  DEFAULT_HOST = "localhost";
    
    /** Default Vayacondios server port. */
    public static Integer DEFAULT_PORT = 9000;
    
    private String     _host;
    private Integer    _port;

    private DefaultHttpClient sync;
    private AsyncHttpClient   async;
    private Gson              serializer;
    
    /**
     * Create a new HTTPClient specifying all options.
     *
     * Set the host and port for the Vayacondios server as well as the
     * organization for the client and whether the client should be in
     * "dry-run" mode.
     *
     * <blockquote><pre>{@code
     * VayacondiosClient client = new HTTPClient("example.com", 1234, "website", true);
     * }</pre></blockquote>
     * 
     * @param host host of Vayacondios server
     * @param port port of Vayacondios server
     * @param organization name of the organization to read/write data for
     * @param shouldDryRun whether or not to be in "dry-run" mode
     */
    public HTTPClient(String host, Integer port, String organization, Boolean shouldDryRun) {
	super(organization, shouldDryRun);
	this._host       = host;
	this._port       = port;
	this.sync        = new DefaultHttpClient();
	this.async       = new AsyncHttpClient();
	this.serializer  = new GsonBuilder()
	    .disableHtmlEscaping()
	    .serializeNulls()
	    .create();
    }

    /**
     * Create a new HTTPClient with the given options.
     *
     * Set the host and port for the Vayacondios server as well as the
     * organization for the client.
     *
     * <blockquote><pre>{@code
     * VayacondiosClient client = new HTTPClient("example.com", 1234, "website");
     * }</pre></blockquote>
     * 
     * @param host host of Vayacondios server
     * @param port port of Vayacondios server
     * @param organization name of the organization to read/write data for
     */
    public HTTPClient(String host, Integer port, String organization) {
	this(host, DEFAULT_PORT, organization, false);
    }

    /**
     * Create a new HTTPClient on the default port with the given
     * options.
     *
     * Set the host for the Vayacondios server as well as the
     * organization for the client.
     *
     * <blockquote><pre>{@code
     * VayacondiosClient client = new HTTPClient("example.com", "website");
     * }</pre></blockquote>
     * 
     * @param host host of Vayacondios server
     * @param organization name of the organization to read/write data for
     */
    public HTTPClient(String host, String organization) {
	this(host, DEFAULT_PORT, organization, false);
    }
    
    /**
     * Create a new HTTPClient for a local Vayacondios server for the
     * given organization.
     *
     * This is most useful when developing or testing with
     * Vayacondios.
     * 
     * <blockquote><pre>{@code
     * VayacondiosClient client = new HTTPClient("website");
     * }</pre></blockquote>
     * 
     * @param organization name of the organization to read/write data for
     */
    public HTTPClient(String organization) {
	this(DEFAULT_HOST, DEFAULT_PORT, organization, false);
    }

    /**
     * Host of the Vayacondios server this client will send requests
     * to.
     * 
     * @return the hostname
     */
    public String  host() { return _host; }
    
    /**
     * Port of the Vayacondios server this client will send requests
     * to.
     *
     * @return the port number
     */
    public Integer port() { return _port; }

    /**
     * The HTTP client used for making synchronous HTTP requests.
     * <p>
     * Requests made with this client will block until a response
     * comes back from the server.
     * <p>
     * Here's an example of how to retrieve an event with a a given ID
     * (something that's not wrapped with a method in the {@link
     * VayacondiosClient} class):
     *
     * <blockquote><pre>{@code
     * HttpGet getRequest = new HttpGet(client.url("event", "transactions", "39487"));
     * HttpResponse response = client.synchronousClient().execute(getRequest)
     * // Parse response body as JSON text, do stuff...
     * }</pre></blockquote>
     *
     * See the <a href="http://hc.apache.org/httpclient-3.x/">Apache
     * commons HttpClient</a> library for more details.
     * 
     * @return the client
     */
    public DefaultHttpClient synchronousClient()  { return sync;  }
    
    /**
     * The HTTP client used for making asynchronous HTTP requests.
     * <p>
     * Requests made with this client are non-blocking.
     * <p>
     * Here's an example of how to retrieve an event with a a given ID
     * (something that's not wrapped with a method in the {@link
     * VayacondiosClient} class):
     *
     * <blockquote><pre>{@code
     * AsyncHttpClient asyncHttpClient = client.asynchronousClient();
     * Future<Response> future = asyncHttpClient.prepareGet(client.url("event", "transactions", "39487")).execute();
     * Response response = future.get();
     * // Parse response body as JSON text, do stuff...
     * }</pre></blockquote>
     * 
     * See the <a
     * href="https://github.com/AsyncHttpClient/async-http-client">AsyncHttpClient</a>
     * library for more details.
     * 
     * @return the client
     */
    public AsyncHttpClient asynchronousClient() { return async; }
    
    /** Close any open connections to the Vayacondios server.
     *
     * Take caution calling this method immediately after asynchronous
     * calls by the client.  The following code would cause an error
     * and is <b>not</b> the preferred way to use a
     * <code>VayacondiosClient</code> instance:
     *
     * <blockquote><pre>{@code
     * // Do NOT do this
     * private void incrementTotal(Integer n) {
     *   VayacondiosClient client = new HttpClient("my_organization");
     *   client.set("project", "counter", n);
     *   client.close();
     * }
     * }</pre></blockquote>
     *
     * because the call to <code>client.close()</code> will occur
     * before the HTTP request started by the call to
     * <code>client.set</code> finishes.
     *
     * The proper way to use a <code>VayacondiosClient</code> is to
     * set up the client during initialization of your appilcation and
     * only close it at the end -- when you can afford to throw in a
     * call to {@link Thread#sleep(long millis)} if you need to.
     * 
     * */
    @Override
    public void close() {
	async.close();
    };

    /**
     * The URL this client will use to make a query to the given path
     * segments.  This method is not required during "normal" usage of
     * the client (though it is called internally when making
     * requests) but comes in handy when debugging or when using this
     * Vayacondios client's own synchronous and/or asynchronous HTTP
     * clients.
     *
     * <blockquote><pre>{@code
     * client.url("event", "transactions", "9783") // URL for retrieving and event by ID
     * client.url("foo", "bar", "baz", "boof")     // garbage URL...
     * }</pre></blockquote>
     * 
     * @param pathSegments each path segment
     * @return the URL for the given path segments, including domain, version, and organization
     */
    public String url(String... pathSegments) {
	ArrayList urlSegments = new ArrayList();
	urlSegments.add("http://" + _host + ":" + _port);
	urlSegments.add(BaseClient.VERSION);
	urlSegments.add(organization());
	urlSegments.addAll(Arrays.asList(pathSegments));
	return StringUtils.join(urlSegments, "/");
    }
    
    //----------------------------------------------------------------------------
    // BaseClient Private API Implementation
    //----------------------------------------------------------------------------

    @Override
    protected void performAnnounce(String topic, Map<String,Object> event, String id) throws IOException {
	async.preparePost(url("event", topic, id)).setBody(toJson(event)).execute(asyncResponseHandler());
    }
    @Override
    protected void performAnnounce(String topic, Map<String,Object> event) throws IOException {
	async.preparePost(url("event", topic)).setBody(toJson(event)).execute(asyncResponseHandler());
    }
    
    @Override
    protected List<Map<String,Object>> performEvents(String topic, Map<String,Object> query) throws IOException {
	try {
	    return parseList(sync.execute(new HttpGetWithBody(url("events", topic), toJson(query)), syncResponseHandler()));
	} catch (URISyntaxException e) {
	    LOG.error("Failed to search events <" + topic + ">", e);
	    return new ArrayList();
	}
    }

    @Override
    protected Map<String,Object> performGet(String topic) throws IOException {
	return parseMap(sync.execute(new HttpGet(url("stash", topic)), syncResponseHandler()));
    }
    
    @Override
    protected Map<String,Object> performGetMap(String topic, String id) throws IOException {
	return parseMap(sync.execute(new HttpGet(url("stash", topic, id)), syncResponseHandler()));
    }
    @Override
    protected List<Object> performGetList(String topic, String id) throws IOException {
	return parseList(sync.execute(new HttpGet(url("stash", topic, id)), syncResponseHandler()));
    }
    @Override
    protected String performGetString(String topic, String id) throws IOException {
	return parseString(sync.execute(new HttpGet(url("stash", topic, id)), syncResponseHandler()));
    }
    @Override
    protected Double performGetDouble(String topic, String id) throws IOException {
	return parseDouble(sync.execute(new HttpGet(url("stash", topic, id)), syncResponseHandler()));
    }

    @Override
    protected List<Map<String,Object>> performStashes(Map<String,Object> query) throws IOException {
	try {
	    return parseList(sync.execute(new HttpGetWithBody(url("stashes"), toJson(query)), syncResponseHandler()));
	} catch (URISyntaxException e) {
	    LOG.error("Failed to search stashes", e);
	    return new ArrayList();
	}
    }

    @Override
    protected void performMerge(String topic, String id, Object value) throws IOException {
	async.preparePut(url("stash", topic, id)).setBody(toJson(value)).execute(asyncResponseHandler());
    }
    @Override
    protected void performMerge(String topic, Map<String,Object> value) throws IOException {
	async.preparePut(url("stash", topic)).setBody(toJson(value)).execute(asyncResponseHandler());
    }
    
    @Override
    protected void performSet(String topic, String id, Object value) throws IOException {
	async.preparePost(url("stash", topic, id)).setBody(toJson(value)).execute(asyncResponseHandler());
    }
    @Override
    protected void performSet(String topic, Map<String,Object> value) throws IOException {
	async.preparePost(url("stash", topic)).setBody(toJson(value)).execute(asyncResponseHandler());
    }

    @Override
    protected void performDelete(String topic, String id) throws IOException {
	async.prepareDelete(url("stash", topic, id)).execute(asyncResponseHandler());
    }
    @Override
    protected void performDelete(String topic) throws IOException {
	async.prepareDelete(url("stash", topic)).execute(asyncResponseHandler());
    }

    //----------------------------------------------------------------------------
    // Private Methods
    //----------------------------------------------------------------------------

    private String toJson(Object object) {
	return serializer.toJson(object);
    }

    private BasicResponseHandler syncResponseHandler() {
	return new BasicResponseHandler();
    }
    
    private AsyncResponseHandler asyncResponseHandler() {
	return new AsyncResponseHandler();
    }

    private Map<String,Object> parseMap(String json) throws JsonParseException {
	return serializer.fromJson(json, Map.class);
    }
    
    private List parseList(String json) throws JsonParseException {
	return serializer.fromJson(json, List.class);
    }

    private String parseString(String json) throws JsonParseException {
	return serializer.fromJson(json, String.class);
    }

    private Double parseDouble(String json) throws JsonParseException {
	return serializer.fromJson(json, Double.class);
    }
    
}
