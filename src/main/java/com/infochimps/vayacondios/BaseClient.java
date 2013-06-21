package com.infochimps.vayacondios;

import java.util.Map;
import java.util.List;
import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Base class for all concrete implementations of a Vayacondios client.
 * <p>
 * Is fixed to a specific organization at instantiation time since the
 * common use case is reading/writing data for a single organization
 * at a time.  If reading/writing data for multiple organizations
 * simultaneously, use multiple client instances.
 * <p>
 * Can be instantiated in "dry-run" mode in which it will not actually
 * make any requests to the server, merely log its output.
 * <p>
 * Implements the {@link VayacondiosClient} interface by wrapping each
 * method of is API (e.g. - {@link VayacondiosClient#announce(String
 * topic, Map event)}) with logic for handling arguments, errors, and
 * "dry-run" mode, ultimately delegating to a (protected) method to
 * perform the actual request (e.g. - {@link
 * BaseClient#performAnnounce(String topic, Map event)}).  Subclasses
 * should override these methods to provide a concrete implementation
 * of a Vayacondios client.
 */
public class BaseClient implements VayacondiosClient {

  //----------------------------------------------------------------------------
  // Initialization & Properties
  //----------------------------------------------------------------------------

    public static String VERSION = "v2";
    
    private static Logger LOG = LoggerFactory.getLogger(BaseClient.class);

    private String  _organization;
    private Boolean _dryRun;

    /**
     * Create a new BaseClient instance for the given
     * organization. optionally in "dry-run" mode.
     *
     * <blockquote><pre>{@code
     * VayacondiosClient client = new BaseClient("my_organization", true); // client in dry-run mode
     * }</pre></blockquote>
     * 
     * @param organization name of the organization to read/write data for
     * @param shouldDryRun whether or not to enter "dry-run" mode
     */
    public BaseClient(String organization, Boolean shouldDryRun) {
	this._organization = organization;
	this._dryRun       = shouldDryRun;
    }

    /**
     * Create a new BaseClient instance for the given organization.
     *
     * @param organization name of the organization to read/write data for
     */
    public BaseClient(String organization) {
	this(organization, false);
    }

    /**
     * Is this client in "dry-run" mode?
     * <p>
     * When in "dry-run" mode, the client will not actually make any
     * requests to the server, it will merely log all its attempts at
     * an elevated level.
     * @return whether or not the client is in "dry-run" mode
     */
    public Boolean dryRun() {
	return _dryRun;
    }

    /**
     * The organization this client will read/write data for.
     * 
     * @return name of the organization
     */
    public String organization() {
	return _organization;
    }

  //----------------------------------------------------------------------------
  // Public API 
  //----------------------------------------------------------------------------

    /**
     * {@inheritDoc}
     */
    @Override
    public void announce(String topic, Map<String,Object> event) {
	logRequest("Announcing <" + topic + ">");
	if (dryRun()) return;
	try {
	    performAnnounce(topic, event);
	} catch (IOException e) {
	    LOG.error("Announcing <" + topic + ">", e);
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public void announce(String topic, Map<String,Object> event, String id) {
	logRequest("Announcing <" + topic + "/" + id + ">");
	if (dryRun()) return;
	try {
	    performAnnounce(topic, event, id);
	} catch (IOException e) {
	    LOG.error("Announcing <" + topic + "/" + id + ">", e);
	}
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<Map<String,Object>> events(String topic, Map<String,Object> query) {
	logRequest("Searching events <" + topic + ">");
	if (dryRun()) return null;
	try { 
	    return performEvents(topic, query);
	} catch (IOException e) {
	    LOG.error("Searching events <" + topic + ">", e);
	    return null;
	}
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Map<String,Object> get(String topic) {
	logRequest("Fetching <" + topic + ">");
	if (dryRun()) return null;
	try {
	    return performGet(topic);
	} catch (IOException e) {
	    LOG.error("Fetching <" + topic + ">");
	    return null;
	}
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public Map<String,Object> getMap(String topic, String id) {
	logRequest("Fetching Map <" + topic + "/" + id + ">");
	if (dryRun()) return null;
	try {
	    return performGetMap(topic, id);
	} catch (IOException e) {
	    LOG.error("Fetching Map <" + topic + "/" + id + ">", e);
	    return null;
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public List getList(String topic, String id) {
	logRequest("Fetching List <" + topic + "/" + id + ">");
	if (dryRun()) return null;
	try {
	    return performGetList(topic, id);
	} catch (IOException e) {
	    LOG.error("Fetching List <" + topic + "/" + id + ">", e);
	    return null;
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public String getString(String topic, String id) {
	logRequest("Fetching String <" + topic + "/" + id + ">");
	if (dryRun()) return null;
	try {
	    return performGetString(topic, id);
	} catch (IOException e) {
	    LOG.error("Fetching String <" + topic + "/" + id + ">", e);
	    return null;
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public Double getDouble(String topic, String id) {
	logRequest("Fetching Double <" + topic + "/" + id + ">");
	if (dryRun()) return null;
	try {
	    return performGetDouble(topic, id);
	} catch (IOException e) {
	    LOG.error("Fetching Double <" + topic + "/" + id + ">", e);
	    return null;
	}
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<Map<String,Object>> stashes(Map<String,Object> query) {
	logRequest("Searching stashes");
	if (dryRun()) return null;
	try { 
	    return performStashes(query);
	} catch (IOException e) {
	    LOG.error("Searching stashes", e);
	    return null;
	}
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void set(String topic, Map<String,Object> value) {
	logRequest("Replacing <" + topic + ">");
	if (dryRun()) return;
	try {
	    performSet(topic, value);
	} catch (IOException e) {
	    LOG.error("Replacing <" + topic + ">", e);
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public void set(String topic, String id, Object value) {
	logRequest("Replacing <" + topic + "/" + id + ">");
	if (dryRun()) return;
	try {
	    performSet(topic, id, value);
	} catch (IOException e) {
	    LOG.error("Replacing <" + topic + "/" + id + ">", e);
	}
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void merge(String topic, Map<String,Object> value) {
	logRequest("Merging <" + topic + ">");
	if (dryRun()) return;
	try {
	    performMerge(topic, value);
	} catch (IOException e) {
	    LOG.error("Merging <" + topic + ">", e);
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public void merge(String topic, String id, Object value) {
	logRequest("Merging <" + topic + "/" + id + ">");
	if (dryRun()) return;
	try {
	    performMerge(topic, id, value);
	} catch (IOException e) {
	    LOG.error("Merging <" + topic + "/" + id + ">", e);
	}
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void delete(String topic) {
	logRequest("Deleting <" + topic + ">");
	if (dryRun()) return;
	try {
	    performDelete(topic);
	} catch (IOException e) {
	    LOG.error("Deleting <" + topic + ">");
	}
    }
    /**
     * {@inheritDoc}
     */
    @Override
    public void delete(String topic, String id) {
	logRequest("Deleting <" + topic + "/" + id + ">");
	if (dryRun()) return;
	try {
	    performDelete(topic, id);
	} catch (IOException e) {
	    LOG.error("Deleting <" + topic + "/" + id + ">");
	}
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void close() {};
    
  //----------------------------------------------------------------------------
  // Private API 
  //----------------------------------------------------------------------------
    
    protected void performAnnounce(String topic, Map<String,Object> event, String id) throws IOException {}
    protected void performAnnounce(String topic, Map<String,Object> event) throws IOException {}
    
    protected List<Map<String,Object>> performEvents(String topic, Map<String,Object> query) throws IOException { return null; }

    protected Map<String,Object> performGet(String topic) throws IOException { return null; }
    
    protected Map<String,Object> performGetMap(String topic, String id) throws IOException { return null; }
    protected List performGetList(String topic, String id) throws IOException { return null; }
    protected String performGetString(String topic, String id) throws IOException { return null; }
    protected Double performGetDouble(String topic, String id) throws IOException { return null; }

    protected List<Map<String,Object>> performStashes(Map<String,Object> query) throws IOException { return null; }

    protected void performMerge(String topic, String id, Object value) throws IOException {}
    protected void performMerge(String topic, Map<String,Object> value) throws IOException {}

    protected void performSet(String topic, String id, Object value) throws IOException {}
    protected void performSet(String topic, Map<String,Object> value) throws IOException {}

    protected void performDelete(String topic, String id) throws IOException {}
    protected void performDelete(String topic) throws IOException {}

    private void logRequest(String message) {
	if (dryRun()) {
	    LOG.info(message);
	} else {
	    LOG.debug(message);
	}
    }
}
