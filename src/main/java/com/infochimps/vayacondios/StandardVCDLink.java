package com.infochimps.vayacondios;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.google.gson.JsonIOException;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonParseException;
import com.google.gson.JsonSerializer;
import com.google.gson.JsonSerializationContext;
import com.google.gson.JsonSyntaxException;


import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import java.net.URL;

import org.slf4j.Logger;

import com.infochimps.util.DebugUtil;
import com.infochimps.util.HttpHelper;
import static com.infochimps.util.CurrentClass.getLogger;
import static com.infochimps.vayacondios.ItemSets.Item;

public class StandardVCDLink extends LinkToVCD {
  public StandardVCDLink(ItemSets parent) { super(parent); }

  public List<Item> fetch(String topic, String id) throws IOException {
    BufferedReader reader = null;
    try {
      reader = openUrl(getParent().urlString(PATH_COMPONENT, topic, id));
    } catch (FileNotFoundException ex) {
      // In the case of a 404, return an empty set.
      return new ArrayList();
    }
    String line = reader.readLine();
    JsonElement response;
    JsonElement itemSet;

    ArrayList<Item> result = new ArrayList<Item>();

    // assume Vayacondios response comes in a single line
    if (line != null &&
	(response = PARSER.parse(line)).isJsonObject() &&
	(itemSet = (response.getAsJsonObject().get("contents"))).isJsonArray()) {
      for (JsonElement elem : itemSet.getAsJsonArray()) {
	if (!elem.isJsonPrimitive()) {
	  LOG.warn("ignoring non-primitive in itemset: " + elem);
	  continue;
	}

	JsonPrimitive item = elem.getAsJsonPrimitive();
	if      (item.isBoolean()) result.add(new Item(item.getAsBoolean()));
	else if (item.isNumber())  result.add(new Item(item.getAsNumber()));
	else if (item.isString())  result.add(new Item(item.getAsString()));

	else LOG.warn("ignoring unrecognized type in itemset: " + item);
      }
    }
    
    if ((line = reader.readLine()) != null)
      LOG.warn("expected eof but saw " + line);

    reader.close();

    return result;
  }

  public void mutate(String method,
		     String topic,
		     String id,
		     List<Item> items) throws IOException {
    
    // serialize the items
    HashMap content = new HashMap();
    content.put("contents", items);
    String body = GSON.toJson(content);
    // connect to our standard path
    URL url = new URL(getParent().urlString(PATH_COMPONENT, topic, id));
    HttpURLConnection connection = (HttpURLConnection)
      ((Boolean.valueOf(System.getProperty("ics.http.use_charles"))) ? 
       url.openConnection(DebugUtil.useCharles()) : url.openConnection());

    // configure connection
    connection.setDoOutput(true);

    // NOTE: Uncommenting this (and not calling
    // connection.getInputStream()) causes Java to hang without
    // sending its payload.

    // connection.setDoInput(false);

    if (method.equals("DELETE")) {
      connection.setRequestMethod("PUT");
      connection.setRequestProperty("X-Method", "DELETE");
    } else if (method.equals("PATCH")) {
      connection.setRequestMethod("PUT");
      connection.setRequestProperty("X-Method", "PATCH");
    } else connection.setRequestMethod(method);
    connection.setRequestProperty("Content-Type", "application/json"); 
    connection.setRequestProperty("Accept", "*/*");
    connection.setRequestProperty("Content-Length",
				  Integer.toString(body.getBytes().length));
    connection.setUseCaches(false);

    LOG.debug("sending: " + body);
    LOG.debug("via " +
	      connection.getRequestMethod() +
	      " to " +
	      getParent().urlString(PATH_COMPONENT, topic, id));

    // connect and write
    OutputStream os = connection.getOutputStream();
    os.write(body.getBytes("UTF-8"));
    os.flush();
    os.close();

    // ignore reponse
    InputStream is = connection.getInputStream();

    LOG.trace("ignoring response from Vayacondios.");
    byte buf[] = new byte[256];
    while (is.read(buf) != -1);
    LOG.trace("response ignored.");
    is.close();

    // fin.
    connection.disconnect();
  }

  private BufferedReader openUrl(String urlString) throws IOException {
    HashMap headers = new HashMap();
    headers.put("Accept", "*/*");
    return HttpHelper.open(LOG, urlString, headers, Charset.forName("UTF-8"));
  }
  
  private static final Gson GSON                = new GsonBuilder().
    registerTypeAdapter(Item.class, new Item.Serializer()).
    create();
  private static final JsonParser PARSER	= new JsonParser();
  private static final Logger LOG               = getLogger();
  private static final String PATH_COMPONENT    = "itemset";
}
