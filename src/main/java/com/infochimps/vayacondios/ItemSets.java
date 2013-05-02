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
import java.lang.reflect.InvocationTargetException;
import java.net.HttpURLConnection;
import java.util.ArrayList;
import java.util.List;

import java.net.URL;

import org.slf4j.Logger;

/**
 * This is the first level of the Vayacondios path-building hierarchy
 * that is capable of directly manipulating itemsets.
 */
public class ItemSets<LinkType extends LinkToVCD> extends Organization {
  public ItemSets(PathBuilder delegate) { super(delegate); }

  /**
   * @param linkClass for testing purposes. can be used to shim up a
   * dummy vayacondios session.
   */
  public ItemSets(Organization org, LinkType linkToVCD) {
    super(org);
    _org = org;
    (_vcdLink = linkToVCD).setParent(this);
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
    return _vcdLink.fetch(topic, id);
  }

  /**
   * Creates a new itemset with the specified topic and id, clobbering
   * any existing itemset with the same topic and id.
   * 
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   * @param items items whose existence should be ensured in the set.
   */
  public void create(String topic,
                     String id,
                     List<Item> items) throws IOException {
    mutate("PUT", topic, id, items);
  }

  /**
   * Ensures the absence of the specified items from the specified itemset.q
   * 
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   * @param items items whose absence should be ensured in the set.
   */
  public void remove(String topic,
                     String id,
                     List<Item> items) throws IOException {
    mutate("DELETE", topic, id, items);
  }

  /**
   * Updates the current value of an itemset, ensuring the existence
   * of the specified items.
   * 
   * @param topic A Vayacondios topic has many ids. See vayacondios
   *              documentation for further details.
   * @param id A Vayacondios id, together with the server,
   *           organization, and topic, specifies a unique
   *           itemset.
   * @param items items whose existence should be ensured in the set.
   */
  public void update(String topic,
                     String id,
                     List<Item> items) throws IOException {
    mutate("PATCH", topic, id, items);
  }

  //----------------------------------------------------------------------------
  // API HTTP path components
  //----------------------------------------------------------------------------

  String getOrganization() {
    return ((Organization)getDelegate()).getOrganization();
  }

  //----------------------------------------------------------------------------

  protected void mutate(String method,
                        String topic,
                        String id,
                        List<Item> items) throws IOException {
    _vcdLink.mutate(method, topic, id, items);
  }

  private LinkType _vcdLink;
  private Organization _org;

  private static final Logger LOG               = getLogger();

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
     * @see ItemSets#fetch
     */
    public List<Item> fetch(String id) throws IOException {
      return fetch(getTopic(), id);
    }

    /**
     * @see ItemSets::create
     */
    public void create(String id, List<Item> items) throws IOException {
      create(getTopic(), id, items);
    }

    /**
     * @see ItemSets#remove
     */
    public void remove(String id, List<Item> items) throws IOException {
      remove(getTopic(), id, items);
    }

    /**
     * @see ItemSets#update
     */
    public void update(String id, List<Item> items) throws IOException {
      update(getTopic(), id, items);
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
     * @see ItemSets#fetch
     */
    public List<Item> fetch() throws IOException {
      return fetch(getId());
    }

    /**
     * @see ItemSets#create
     */
    public void create(List<Item> items) throws IOException {
      create(getId(), items);
    }

    /**
     * @see ItemSets#remove
     */
    public void remove(List<Item> items) throws IOException {
      remove(getId(), items);
    }

    /**
     * @see ItemSets#update
     */
    public void update(List<Item> items) throws IOException {
      update(getId(), items);
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
