package com.infochimps.vayacondios;

import java.util.Map;
import java.util.List;

interface VayacondiosClient {

    void announce(String topic, Map event, String id);
    void announce(String topic, Map event);

    List events(String topic, Map query);

    Object get(String topic, String id);
    Object get(String topic);

    List stashes(Map query);
    
    void merge(String topic, String id, Map value);
    void merge(String topic, Map value);

    void set(String topic, String id, Map value);
    void set(String topic, Map value);

    void delete(String topic, String id);
    void delete(String topic);
    
}
