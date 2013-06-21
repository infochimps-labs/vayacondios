package com.infochimps.vayacondios;

import java.util.Map;
import java.util.List;

/** This is interface all concrete Vayacondios client classes
 * implement.
 * <p>
 * Your code should type client instances with this interface, as in
 * the following example, which uses a {@link HTTPClient} but still
 * types <code>client</code> as <code>VayacondiosClient</code>:
 * <blockquote><pre>
 * {@code 
 * import com.infochimps.vayacondios.VayacondiosClient;
 * import com.infochimps.vayacondios.HTTPClient;
 *
 * class public HelloClient {
 *   public static void main(String[] args) throws Exception {
 *     VayacondiosClient client = new HTTPClient("my_organization");
 *     
 *     // do stuff...
 *     
 *     Thread.sleep(1000);	// ensure all HTTP requests have been sent before closing the client
 *     client.close()
 *   }
 * }
 * }</pre></blockquote>
 * */
public interface VayacondiosClient {

    /**
     * Announce a new event.
     * <p>
     * Here's an example which announces a suspicious intrusion event:
     *
     * <blockquote><pre>
     * {@code
     * Map event = new HashMap();
     * event.put("ip",       "10.123.123.123");
     * event.put("priority", 3);
     * event.put("type",     "ssh");
     * client.announce("intrusions", event);
     * }</pre></blockquote>
     *
     * Events will be automatically assigned an ID and a timestamp by
     * the server.
     * <p>
     * The timestamp can also be included in the event body:
     *
     * <blockquote><pre>
     * {@code
     * Map event = new HashMap();
     * event.put("ip",       "10.123.123.123");
     * event.put("priority", 3);
     * event.put("type",     "ssh");
     * event.put("time",     "2013-06-18 Tue 16:43 -0500");
     * client.announce("intrusions", event);
     * }</pre></blockquote>
     *
     * @param topic the topic for the event
     * @param event the event body
     */
    void announce(String topic, Map<String,Object> event);

    /**
     * Announce an event with a specified ID.
     * <p>
     * Here's an example which announces a build using the unique ID
     * assigned by the build system as the ID of the event:
     * 
     * <blockquote><pre>
     * {@code
     * Map event = new HashMap();
     * event.put("name",     "Little Stinker");
     * event.put("version",  "1.2.3");
     * event.put("status",   "success");
     * event.put("duration", 183);
     * client.announce("builds", event, "13fe3ff5f13c6b0394cc22501a9617cfe2445c63");
     * }</pre></blockquote>
     *
     * The server will use this ID when saving the event.
     * <p>
     * The server will still generate a timestamp, unless one is
     * included in the event body.
     * 
     * @param topic the topic for the event
     * @param event the event body
     * @param id the ID to save the event with
     */
    void announce(String topic, Map<String,Object> event, String id);
    
    /**
     * Search for events matching some query.
     * <p>
     * Each element of the returned <code>List</code> of events is a
     * <code>Map</code>.
     * <p>
     * The default search behavior implemented by the server is to
     * return up to 50 full events from the last hour on the given
     * <code>topic</code> sorted by timestamp, with the earliest
     * events first.  the last hour with the earliest event first.
     * This will be the response when given an empty query:
     * 
     * <pre><blockquote>
     * {@code
     * Map query = new HashMap(); // empty query
     * List<Map> events = client.events("intrusions", query);
     * }</pre></blockquote>
     *
     * Returned events will match each key/value pair in the query.
     * The following example will only return "intrusion" events with
     * the <code>ip</code> key equal to the value "10.123.123.123":
     * 
     * <blockquote><pre>{@code
     * Map query = new HashMap(); // empty query
     * query.put("ip", "10.123.123.123")
     * List<Map> events = client.events("intrusions", query);
     * }</pre></blockquote>
     *
     * The number of events returned, the fields within each event,
     * the time period, and sorting behavior can all be changed:
     * 
     * <pre><blockquote>
     * {@code
     * // The basic query
     * Map query = new HashMap();
     * query.put("ip", "10.123.123.123")
     *
     * // Change the number of returned events to 1000
     * query.put("limit", 1000);
     *
     * // Change the timeframe from "the last hour" to all of June 9th, CDT
     * query.put("from", "2013-06-09 Tue 00:00:00 -0500");
     * query.put("upto", "2013-06-09 Tue 23:59:59 -0500");
     *
     * // Return just the "type" and "priority" fields
     * List fields = new ArrayList();
     * fields.add("type");
     * fields.add("priority");
     * query.put("fields", fields);
     *
     * // Sort the result set by the "priority" field in ascending order.
     * List sort = new ArrayList();
     * sort.add("priority");
     * sort.add("ascending");
     * query.put("sort", sort);
     *
     * // Perform the search
     * List<Map> events = client.events("intrusions", query);
     * }</pre></blockquote>
     *
     * This method blocks until a response comes back from the server.
     * 
     * @param topic the topic within which to search
     * @param query a query to match events
     * @return the matched events
     */
    List<Map<String,Object>> events(String topic, Map<String,Object> query);

    /**
     * Lookup a stashed value.
     * <p>
     * When given only a topic, Vayacondios server will either return
     * a <code>Map</code> or <code>null</code>.
     *
     * <blockquote><pre>{@code
     * Map firewall = client.get("firewall");
     * if (firewall != null) {
     *   // do stuff...
     * }
     * }</pre></blockquote>
     *
     * @param topic the topic to lookup
     * @return the stashed value or <code>null</code> if it is not found
     */
    Map<String,Object> get(String topic);
    
    /**
     * Lookup a stashed value that is a <code>Map</code>.
     * <p>
     * When given a topic and an ID, Vayacondios server can return any
     * one of
     * 
     * <ul>
     *   <li><code>Map</code></li>
     *   <li><code>List</code></li>
     *   <li><code>String</code></li>
     *   <li><code>Double</code></li>
     *   <li><code>null</code></li>
     * </ul>
     *
     * The appropriate method should therefore be called by the client
     * when anticipating a response of a given type. This method will
     * treat the response like it is a <code>Map</code>:
     *
     * <pre><blockquote>{@code
     * Map firewallRules = getMap("firewall", "rules");
     * if (firewallRules != null) {
     *   // do stuff...
     * }
     * }</pre></blockquote>
     *
     * @param topic the topic of the stashed value
     * @param id the ID of the stashed value
     * @return the stashed value or <code>null</code> if it is not found
     * @see VayacondiosClient#get(String topic)
     * @see VayacondiosClient#getList(String topic, String id)
     * @see VayacondiosClient#getString(String topic, String id)
     * @see VayacondiosClient#getDouble(String topic, String id)
     */
    Map<String,Object> getMap(String topic, String id);

    /**
     * Lookup a stashed value that is a <code>List</code>.
     * <p>
     * When given a topic and an ID, Vayacondios server can return any
     * one of
     * 
     * <ul>
     *   <li><code>Map</code></li>
     *   <li><code>List</code></li>
     *   <li><code>String</code></li>
     *   <li><code>Double</code></li>
     *   <li><code>null</code></li>
     * </ul>
     *
     * The appropriate method should therefore be called by the client
     * when anticipating a response of a given type.  This method will
     * treat the response like it is a <code>List</code>:
     *
     * <pre><blockquote>{@code
     * List firewallServers = getMap("firewall", "servers");
     * if (firewallServers != null) {
     *   // do stuff...
     * }
     * }</pre></blockquote>
     *
     * @param topic the topic of the stashed value
     * @param id the ID of the stashed value
     * @return the stashed value or <code>null</code> if it is not found
     * @see VayacondiosClient#get(String topic)
     * @see VayacondiosClient#getMap(String topic, String id)
     * @see VayacondiosClient#getString(String topic, String id)
     * @see VayacondiosClient#getDouble(String topic, String id)
     */
    List<Object> getList(String topic, String id);

    /**
     * Lookup a stashed value that is a <code>String</code>.
     * <p>
     * When given a topic and an ID, Vayacondios server can return any
     * one of
     * 
     * <ul>
     *   <li><code>Map</code></li>
     *   <li><code>List</code></li>
     *   <li><code>String</code></li>
     *   <li><code>Double</code></li>
     *   <li><code>null</code></li>
     * </ul>
     *
     * The appropriate method should therefore be called by the client
     * when anticipating a response of a given type.  This method will
     * treat the response like it is a <code>String</code>:
     *
     * <pre><blockquote>{@code
     * String firewallName = getMap("firewall", "name");
     * if (firewallName != null) {
     *   // do stuff...
     * }
     * }</pre></blockquote>
     *
     * @param topic the topic of the stashed value
     * @param id the ID of the stashed value
     * @return the stashed value or <code>null</code> if it is not found
     * @see VayacondiosClient#get(String topic)
     * @see VayacondiosClient#getMap(String topic, String id)
     * @see VayacondiosClient#getList(String topic, String id)
     * @see VayacondiosClient#getDouble(String topic, String id)
     */
    String getString(String topic, String id);

    /**
     * Lookup a stashed value that is a <code>Double</code>.
     * <p>
     * When given a topic and an ID, Vayacondios server can return any
     * one of
     * 
     * <ul>
     *   <li><code>Map</code></li>
     *   <li><code>List</code></li>
     *   <li><code>String</code></li>
     *   <li><code>Double</code></li>
     *   <li><code>null</code></li>
     * </ul>
     *
     * The appropriate method should therefore be called by the client
     * when anticipating a response of a given type.  This method will
     * treat the response like it is a <code>Double</code>:
     *
     * <pre><blockquote>{@code
     * Double firewallAverageLatency = getMap("firewall", "average_latency");
     * if (firewallAverageLatency != null) {
     *   // do stuff...
     * }
     * }</pre></blockquote>
     *
     * @param topic the topic of the stashed value
     * @param id the ID of the stashed value
     * @return the stashed value or <code>null</code> if it is not found
     * @see VayacondiosClient#get(String topic)
     * @see VayacondiosClient#getMap(String topic, String id)
     * @see VayacondiosClient#getList(String topic, String id)
     * @see VayacondiosClient#getString(String topic, String id)
     */
    Double getDouble(String topic, String id);
    
    /**
     * Search for stashed values matching a query.
     * <p>
     * Each element of the returned <code>List</code> of stashes is a
     * <code>Map</code>.
     *
     * The default search behavior implemented by the server is to
     * return up to 50 full stashes sorted in ascending order by
     * topic.  This will be the response when given an empty query:
     *
     * <blockquote><pre>{@code
     * Map query = new HashMap(); // empty query
     * List<Map> events = client.stashes(query);
     * }</pre></blockquote>
     *
     * Returned stashes will match each key/value pair in the query.
     * The following example will only return stashed values which
     * have the <code>environment</code> key equal to the value
     * "production":
     * 
     * <blockquote><pre>{@code
     * Map query = new HashMap(); // empty query
     * query.put("environment", "production")
     * List<Map> events = client.stashes(query);
     * }</pre></blockquote>
     * 
     * The number of stashes returned and sorting behavior can all be
     * changed:
     * 
     * <pre><blockquote>
     * {@code
     * // The basic query
     * Map query = new HashMap();
     * query.put("environment", "production");
     *
     * // Change the number of returned stashes to 1000
     * query.put("limit", 1000);
     *
     * // Sort the result set by the "priority" field in ascending order.
     * List sort = new ArrayList();
     * sort.add("priority");
     * sort.add("ascending");
     * query.put("sort", sort);
     *
     * // Perform the search
     * List<Map> events = client.events("intrusions", query);
     * }</pre></blockquote>
     *
     * @param query a query to match stashed values
     * @return the matched stashed values
     */
    List<Map<String,Object>> stashes(Map<String,Object> query);
    
    /**
     * Stash the given value for the given topic.
     * <p>
     * The current value for the given topic will be overwritten.
     * <p>
     * When stashing with only a topic, the Vayacondios server
     * requires that the value be a <code>Map</code>:
     *
     * <blockquote><pre>{@code
     * Map value = new HashMap();
     * value.put("host", "localhost");
     * value.put("port", 80);
     * client.set("server", value);
     * }</pre></blockquote>
     *
     * @param topic the topic to stash a value for
     * @param value the value to stash
     */
    void set(String topic, Map<String,Object> value);

    /**
     * Stash the given value for the given topic and ID.
     * <p>
     * The current value for the given topic and ID will be
     * overwritten.
     * <p>
     * When stashing with a topic and ID, the Vayacondios server
     * accepts as a value any of
     * 
     * <ul>
     *   <li><code>Map</code></li>
     *   <li><code>List</code></li>
     *   <li><code>String</code></li>
     *   <li><code>Double</code></li>
     *   <li><code>null</code></li>
     * </ul>
     *
     * Here is an example:
     *
     * <blockquote><pre>{@code
     * client.set("server", "host", "localhost");
     * client.set("server", "port", 80);
     * }</pre></blockquote>
     *
     * @param topic <doc>
     * @param value <doc>
     */
    void set(String topic, String id, Object value);
    
    /**
     * Merge the given value for the given topic.
     * <p>
     * If a value already exists for the given topic, the new value
     * will be merged into the old value.
     * <p>
     * When stashing with only a topic, the Vayacondios server
     * requires that the value be a <code>Map</code>.
     *
     * <blockquote><pre>{@code
     * Map value = new HashMap();
     * value.put("host", "localhost");
     * value.put("port", 80);
     * client.merge("server", value);
     * }</pre></blockquote>
     * 
     * @param topic the topic to merge a value for
     * @param value the new value to merge
     */
    void merge(String topic, Map<String,Object> value);

    /**
     * Merge the given value for the given topic and ID.
     * <p>
     * If a value already exists for the given topic and ID, the new
     * value will be "merged" into the old value in a type-aware way.
     * <p>
     * When stashing with a topic and ID, the Vayacondios server
     * accepts as a value any of
     * 
     * <ul>
     *   <li><code>Map</code>: merged</li>
     *   <li><code>List</code>: concatenated</li>
     *   <li><code>String</code>: concatenated</li>
     *   <li><code>Double</code>: incremented</li>
     *   <li><code>null</code>: set as is</li>
     * </ul>
     *
     * Type-aware merging means that this method can be used for
     * implementing shared counters and other distributed patterns:
     *
     * <blockquote><pre>{@code
     * Map value = new HashMap();
     * client.merge("server", "error_count", 1); // increments error_count by 1
     * }</pre></blockquote>
     * 
     * @param topic the topic to merge a value for
     * @param value the new value to merge
     */
    void merge(String topic, String id, Object value);
    
    /**
     * Delete the value stashed for a given topic.
     *
     * <blockquote><pre>{@code
     * client.delete("firewall");
     * }</pre></blockquote>
     * 
     * @param topic the topic to delete
     */
    void delete(String topic);

    /**
     * Delete the value stashed for a given topic and ID.
     *
     * <blockquote><pre>{@code
     * client.delete("firewall", "rules");
     * }</pre></blockquote>
     * 
     * @param topic the topic to delete
     * @param id the ID to delete
     */
    void delete(String topic, String id);

    
    /** Close this client.
     * 
     * */
    void close();
    
}
