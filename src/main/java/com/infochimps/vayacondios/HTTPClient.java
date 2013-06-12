package com.infochimps.vayacondios;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.regex.Pattern;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.ArrayUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.http.client.methods.HttpEntityEnclosingRequestBase;
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

public class HTTPClient extends BaseClient {

    private class HttpGetWithBody extends HttpEntityEnclosingRequestBase {
	
	public final static String METHOD_NAME = "GET";

	HttpGetWithBody(String uri, String body) throws URISyntaxException, UnsupportedEncodingException {
	    super();
	    setURI(new URI(uri));
	    setEntity(new StringEntity(body));
	}
	
	@Override
	public String getMethod() {
	    return METHOD_NAME;
	}
    }

    private class SyncResponseHandler extends BasicResponseHandler {
	public String handleResponse(HttpResponse response) {
	    return ((StringEntity) response.getEntity()).toString();
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
    
    public static String  DEFAULT_HOST = "localhost";
    public static Integer DEFAULT_PORT = 9000;
    
    private String     _host;
    private Integer    _port;

    private DefaultHttpClient sync;
    private AsyncHttpClient   async;
    private Gson              serializer;

    private Pattern   integerRegexp = Pattern.compile("^\\d+$");
    private Pattern   floatRegexp   = Pattern.compile("^\\d+\\.\\d+$");
    
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

    public HTTPClient(String host, String organization) {
	this(host, DEFAULT_PORT, organization, false);
    }

    public HTTPClient(String organization) {
	this(DEFAULT_HOST, DEFAULT_PORT, organization, false);
    }

    public String  host() { return _host; }
    public Integer port() { return _port; }

    public DefaultHttpClient synchronousClient()  { return sync;  }
    public AsyncHttpClient   asynchronousClient() { return async; }

    //----------------------------------------------------------------------------
    // BaseClient Private API Implementation
    //----------------------------------------------------------------------------
    
    private void performAnnounce(String topic, Map event, String id) {
	try {
	    async.preparePost(url("event", topic, id)).setBody(toJson(event)).execute(asyncResponseHandler()).get();
	} catch (IOException e) {
	    LOG.error("Failed to announce <" + topic + "/" + id + ">", e);
	}
    }
    private void performAnnounce(String topic, Map event) {
	try {
	    async.preparePost(url("event", topic)).setBody(toJson(event)).execute(asyncResponseHandler());
	} catch (IOException e) {
	    LOG.error("Failed to announce <" + topic + ">", e);
	}
    }
    
    private List performEvents(String topic, Map query) {
	try {
	    HttpGetWithBody getRequest = new HttpGetWithBody(url("events", topic), toJson(query));
	    return (List) parse(sync.execute(getRequest, syncResponseHandler()));
	} catch (IOException e) {
	    LOG.error("Failed to search events <" + topic + ">", e);
	    return new ArrayList();
	}
    }

    private Object performGet(String topic, String id) {
	return null;
    }
    private Object performGet(String topic) {
	return null;
    }

    private List performStashes(Map query) {
	return new ArrayList();
    }

    private void performMerge(String topic, String id, Map value) {
    }
    private void performMerge(String topic, Map value) {
    }
    
    private void performSet(String topic, String id, Map value) {
    }
    private void performSet(String topic, Map value) {
    }

    private void performDelete(String topic, String id) {
    }
    private void performDelete(String topic) {
    }

    //----------------------------------------------------------------------------
    // Private Methods
    //----------------------------------------------------------------------------

    private String url(String... pathSegments) {
	String domain = "http://" + _host + ":" + _port;
	return StringUtils.join(StringUtils.join(ArrayUtils.addAll(pathSegments), "/"), "/");
    }

    private String toJson(Object object) {
	return serializer.toJson(object);
    }

    private SyncResponseHandler syncResponseHandler() {
	return new SyncResponseHandler();
    }
    
    private AsyncResponseHandler asyncResponseHandler() {
	return new AsyncResponseHandler();
    }

    public Object parse(String json) {
	json.replaceAll("^\\s*", "");
	json.replaceAll("\\s*$", "");
	String firstCharacter = json.substring(0,1);
	if (firstCharacter.equals("{")) {
	    return serializer.fromJson(json, Map.class);
	} else if (firstCharacter.equals("[")) {
	    return serializer.fromJson(json, List.class);
	} else if (firstCharacter.equals("\"")) {
	    return serializer.fromJson(json, String.class);
	} else if (integerRegexp.matcher(json).matches()) {
	    return serializer.fromJson(json, Integer.class);
	} else if (floatRegexp.matcher(json).matches()) {
	    return serializer.fromJson(json, Double.class);
	} else {
	    HTTPClient.LOG.error("Could not parse JSON text: " + json);
	    return null;
	}
    }
    
}
