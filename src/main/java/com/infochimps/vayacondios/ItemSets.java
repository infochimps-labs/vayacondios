package com.infochimps.vayacondios;

import static com.infochimps.util.CurrentClass.getLogger;
import com.infochimps.util.DebugUtil;

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
import java.util.HashMap;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.IOException;
import java.lang.reflect.Type;
import java.net.HttpURLConnection;
import java.util.ArrayList;
import java.util.List;

import java.net.URL;

import org.slf4j.Logger;

/**
 * This is the first level of the Vayacondios path-building hierarchy
 * that is capable of directly manipulating itemsets.
 */
public class ItemSets extends Organization {
  public ItemSets(PathBuilder delegate) { super(delegate); }

  public ItemSets(Organization org) {
    super(org);
    _org = org;
  }

  //----------------------------------------------------------------------------
  // next in path hierarchy
  //----------------------------------------------------------------------------

  /**
   * @param topic Vayacondios topic. see Vayacondios documentation for
   *              details.
   * @return new Topic path builder for this organization
   */
  public Topic topic(String topic) { return new Topic(this, topic); }

  //----------------------------------------------------------------------------
  // public operations
  //----------------------------------------------------------------------------

  /**
   * Fetches the current value of an itemset.
   * 
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   * @return a collection of items
   */
  public List<Item> fetch(String topic, String id) throws IOException {
    BufferedReader reader = null;
    try {
      reader = openUrl(urlString(PATH_COMPONENT, topic, id));
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

  /**
   * Creates a new itemset with the specified topic and id, clobbering
   * any existing itemset with the same topic and id.
   * 
   * @param items items whose existence should be ensured in the set.
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   */
  public void create(List<Item> items,
		     String topic,
		     String id) throws IOException {
    mutate("PUT", items, topic, id);
  }

  /**
   * Ensures the absence of the specified items from the specified itemset.q
   * 
   * @param items items whose absence should be ensured in the set.
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   */
  public void remove(List<Item> items,
		     String topic,
		     String id) throws IOException {
    mutate("DELETE", items, topic, id);
  }

  /**
   * Updates the current value of an itemset, ensuring the existence
   * of the specified items.
   * 
   * @param items items whose existence should be ensured in the set.
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   */
  public void update(List<Item> items,
		     String topic,
		     String id) throws IOException {
    mutate("PATCH", items, topic, id);
  }

  //----------------------------------------------------------------------------
  // API HTTP path components
  //----------------------------------------------------------------------------

  String getOrganization() {
    return ((Organization)getDelegate()).getOrganization();
  }

  //----------------------------------------------------------------------------

  protected void mutate(String method,
			List<Item> items,
			String topic,
			String id) throws IOException {

    // serialize the items
    HashMap content = new HashMap();
    content.put("contents", items);
    String body = GSON.toJson(content);
    // connect to our standard path
    URL url = new URL(urlString(PATH_COMPONENT, topic, id));
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
	      urlString(PATH_COMPONENT, topic, id));

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

  private Organization _org;

  private static final JsonParser PARSER	= new JsonParser();
  private static final Logger LOG		= getLogger();
  private static final String PATH_COMPONENT    = "itemset";
  private static final Gson GSON                = new GsonBuilder().
    registerTypeAdapter(Item.class, new Item.Serializer()).
    create();

  //============================================================================
  // Topic
  //============================================================================

  /**
   * A Topic may have many ids, each of which points to a unique
   * Vayacondios itemset.
   */
  public static class Topic extends ItemSets {
    public Topic(PathBuilder delegate) { super(delegate); }

    public Topic(ItemSets sets, String topic) {
      super(sets);
      _sets = sets;
      _topic = topic;
    }

    //--------------------------------------------------------------------------
    // next in path hierarchy
    //--------------------------------------------------------------------------

    /**
     * @param id Vayacondios id. see Vayacondios documentation for
     *           details.
     * @return new itemset for this topic
     */
    public ItemSet itemSet(String id) { return new ItemSet(this, id); }

    //--------------------------------------------------------------------------
    // public operations
    //--------------------------------------------------------------------------

    /**
     * @see ItemSets::fetch
     */
    public List<Item> fetch(String id) throws IOException {
      return fetch(getTopic(), id);
    }

    /**
     * @see ItemSets::create
     */
    public void create(List<Item> items, String id) throws IOException {
      create(items, getTopic(), id);
    }

    /**
     * @see ItemSets::remove
     */
    public void remove(List<Item> items, String id) throws IOException {
      remove(items, getTopic(), id);
    }

    /**
     * @see ItemSets::update
     */
    public void update(List<Item> items, String id) throws IOException {
      update(items, getTopic(), id);
    }

    //--------------------------------------------------------------------------
    // API HTTP path components
    //--------------------------------------------------------------------------

    protected String getTopic() { return _topic; }

    //--------------------------------------------------------------------------
    // fields
    //--------------------------------------------------------------------------

    private ItemSets _sets;
    private String _topic;
  }

  //============================================================================
  // ItemSet
  //============================================================================

  /**
   * A Vayacodios Itemset is manipulated using four API methods
   * implemented in terms of the Vayacondios API.
   */
  public static class ItemSet extends Topic {
    public ItemSet(PathBuilder delegate) { super(delegate); }

    public ItemSet(Topic topic, String id) {
      super(topic);
      _topic = topic;
      _id = id;
    }

    //--------------------------------------------------------------------------
    // public operations
    //--------------------------------------------------------------------------

    /**
     * @see ItemSets::fetch
     */
    public List<Item> fetch() throws IOException {
      return fetch(getId());
    }

    /**
     * @see ItemSets::create
     */
    public void create(List<Item> items) throws IOException {
      create(items, getId());
    }

    /**
     * @see ItemSets::remove
     */
    public void remove(List<Item> items) throws IOException {
      remove(items, getId());
    }

    /**
     * @see ItemSets::update
     */
    public void update(List<Item> items) throws IOException {
      update(items, getId());
    }

    //--------------------------------------------------------------------------
    // API HTTP path components
    //--------------------------------------------------------------------------

    protected String getId() {
      return _id;
    }
  
    protected String getTopic() {
      return ((Topic)getDelegate()).getTopic();
    }

    //--------------------------------------------------------------------------
    // fields
    //--------------------------------------------------------------------------

    private Topic _topic;
    private String _id;
  }

  //============================================================================
  // Item
  //============================================================================

  /**
   * A Vayacondios item can be a boolean, a number, or a string.
   */
  public static class Item {
    static class Serializer implements JsonSerializer {
      public JsonElement serialize(Object item,
				   Type typeOfId,
				   JsonSerializationContext context) {
	return GSON.toJsonTree(Item.class.isAssignableFrom(item.getClass()) ? 
			       ((Item)item).getObject() : item);
      }
      private static final Gson GSON = new Gson();
      private static final Logger LOG = getLogger();
    }

    public Item(Boolean b) {
      _item = b;
      _type = TYPE.BOOLEAN;
    }

    public Item(Number n) {
      _item = n;
      _type = TYPE.NUMBER;
    }

    public Item(String s) {
      _item = s;
      _type = TYPE.STRING;
    }

    public Boolean getAsBoolean() {
      if (_type != TYPE.BOOLEAN)
	throw new ClassCastException("item is not a boolean");
      return (Boolean)_item;
    }

    public Number getAsNumber() {
      if (_type != TYPE.NUMBER)
	throw new ClassCastException("item is not a number");
      return (Number)_item;
    }

    public String getAsString() {
      if (_type != TYPE.STRING)
	throw new ClassCastException("item is not a string");
      return (String)_item;
    }

    public Boolean isBoolean() { return (_type == TYPE.BOOLEAN); }
    public Boolean  isNumber() { return (_type == TYPE.NUMBER ); }
    public Boolean  isString() { return (_type == TYPE.STRING ); }

    public Object getObject() { return _item; }

    public TYPE getType() { return _type; }

    public String toString() {
      return _item.toString() + ":" + _type;
    }

    public boolean equals(Object other) {
      return (Item.class.isAssignableFrom(other.getClass())) ? 
	_item.equals(((Item)other).getObject()) : _item.equals(other);
    }

    //--------------------------------------------------------------------------
    // fields
    //--------------------------------------------------------------------------

    private Object _item;
    private TYPE _type;
    private enum TYPE {BOOLEAN, NUMBER, STRING}
 }
}