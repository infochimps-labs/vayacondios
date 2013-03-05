package com.infochimps.vayacondios;

import static com.infochimps.util.CurrentClass.getLogger;

import com.google.gson.JsonElement;
import com.google.gson.JsonIOException;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonParseException;
import com.google.gson.JsonSyntaxException;

import java.io.BufferedReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;

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
  public Collection<Item> fetch(String topic, String id) throws IOException {
    BufferedReader reader = openUrl(urlString(PATH_COMPONENT, topic, id));
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
	if (item.isBoolean()) result.add(new Item(item.getAsBoolean()));
	if (item.isNumber())  result.add(new Item(item.getAsNumber()));
	if (item.isString())  result.add(new Item(item.getAsString()));

	else LOG.warn("ignoring unrecognized type in itemset: " + item);
      }
    }
    
    if ((line = reader.readLine()) != null)
      LOG.warn("expected eof but saw " + line);

    reader.close();

    return result;
  }

  //----------------------------------------------------------------------------
  // API HTTP path components
  //----------------------------------------------------------------------------

  String getOrganization() {
    return ((Organization)getDelegate()).getOrganization();
  }

  //----------------------------------------------------------------------------
  // fields
  //----------------------------------------------------------------------------

  private Organization _org;

  private static final JsonParser PARSER	= new JsonParser();
  private static final Logger LOG		= getLogger();
  private static final String PATH_COMPONENT    = "itemset";

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
     * Fetches the current value of an itemset.
     * 
     * @param id A Vayacondios id, together with the server,
     *           organization, and topic, specifies a unique
     *           itemset.
     * @return a collection of items
     */
    public Collection<Item> fetch(String id) throws IOException {
      return fetch(getTopic(), id);
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
     * Fetches the current value of this itemset.
     * 
     * @return a collection of items
     */
    public Collection<Item> fetch() throws IOException {
      return fetch(getId());
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
    public enum TYPE {BOOLEAN, NUMBER, STRING}

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

    public Object getObject() { return _item; }

    public TYPE getType() { return _type; }

    public String toString() {
      return _item.toString() + ":" + _type;
    }

    private Object _item;
    private TYPE _type;
  }
}