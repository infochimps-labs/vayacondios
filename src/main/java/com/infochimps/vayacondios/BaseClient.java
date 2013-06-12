package com.infochimps.vayacondios;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BaseClient implements VayacondiosClient {

  //----------------------------------------------------------------------------
  // Initialization & Properties
  //----------------------------------------------------------------------------
    
    private static Logger LOG = LoggerFactory.getLogger(BaseClient.class);

    private String  _organization;
    private Boolean _dryRun;

    public BaseClient(String organization, Boolean shouldDryRun) {
	this._organization = organization;
	this._dryRun       = shouldDryRun;
    }

    public BaseClient(String organization) {
	this(organization, false);
    }

    public Boolean dryRun() {
	return _dryRun;
    }

    public String organization() {
	return _organization;
    }

  //----------------------------------------------------------------------------
  // Public API 
  //----------------------------------------------------------------------------

    public void announce(String topic, Map event, String id) {
	LOG.debug("Announcing <" + topic + "/" + id + ">");
	if (dryRun()) return;
	performAnnounce(topic, event, id);
    }
    
    public void announce(String topic, Map event) {
	LOG.debug("Announcing <" + topic + ">");
	if (dryRun()) return;
	performAnnounce(topic, event);
    }

    public List events(String topic, Map query) {
	LOG.debug("Searching events <" + topic + ">");
	if (dryRun()) return new ArrayList();
	return performEvents(topic, query);
    }

    public Object get(String topic, String id) {
	LOG.debug("Fetching <" + topic + "/" + id + ">");
	if (dryRun()) return null;
	return performGet(topic, id);
    }
    public Object get(String topic) {
	LOG.debug("Fetching <" + topic + ">");
	if (dryRun()) return null;
	return performGet(topic);
    }

    public List stashes(Map query) {
	LOG.debug("Searching stashes");
	if (dryRun()) return new ArrayList();
	return performStashes(query);
    }
    
    public void merge(String topic, String id, Map value) {
	LOG.debug("Merging <" + topic + "/" + id + ">");
	if (dryRun()) return;
	performMerge(topic, id, value);
    }
    public void merge(String topic, Map value) {
	LOG.debug("Merging <" + topic + ">");
	if (dryRun()) return;
	performMerge(topic, value);
    }

    public void set(String topic, String id, Map value) {
	LOG.debug("Replacing <" + topic + "/" + id + ">");
	if (dryRun()) return;
	performSet(topic, id, value);
    }
    public void set(String topic, Map value) {
	LOG.debug("Replacing <" + topic + ">");
	if (dryRun()) return;
	performSet(topic, value);
    }

    public void delete(String topic, String id) {
	LOG.debug("Deleting <" + topic + "/" + id + ">");
	if (dryRun()) return;
	performDelete(topic, id);
    }
    public void delete(String topic) {
	LOG.debug("Deleting <" + topic + ">");
	if (dryRun()) return;
	performDelete(topic);
    }
    
  //----------------------------------------------------------------------------
  // Private API 
  //----------------------------------------------------------------------------
    
    private void performAnnounce(String topic, Map event, String id) {}
    private void performAnnounce(String topic, Map event) {}
    
    private List performEvents(String topic, Map query) { return new ArrayList(); }

    private Object performGet(String topic, String id) { return null; }
    private Object performGet(String topic) { return null; }

    private List performStashes(Map query) { return new ArrayList(); }

    private void performMerge(String topic, String id, Map value) {}
    private void performMerge(String topic, Map value) {}

    private void performSet(String topic, String id, Map value) {}
    private void performSet(String topic, Map value) {}

    private void performDelete(String topic, String id) {}
    private void performDelete(String topic) {}
}
