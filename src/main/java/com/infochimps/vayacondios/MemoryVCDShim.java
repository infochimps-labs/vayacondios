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
import java.util.Map;

import java.net.URL;

import org.slf4j.Logger;

import static com.infochimps.util.CurrentClass.getLogger;
import static com.infochimps.vayacondios.ItemSets.Item;

public class MemoryVCDShim extends LinkToVCD {
  public MemoryVCDShim() {
    _topics = new HashMap<String, Map<String, List<Item>>>();
  }

  public List<Item> fetch(String topicName, String id) {
    Map<String, List<Item>> topic = _topics.get(topicName);
    List<Item> result;

    LOG.trace("topics before fetch: {}", _topics);

    if (topic == null || (result = topic.get(id)) == null) {
      LOG.debug("couldn't find {}.{}. returning empty list", topicName, id);
      return new ArrayList<Item>();
    } else {
      LOG.debug("returning {}.{} => {}", topicName, id, result);
      return result;
    }
  }

  public void mutate(String method,
                     String topicName,
                     String id,
                     List<Item> items) {
    LOG.trace("topics before mutate: {}", _topics);

    Map<String, List<Item>> topic = _topics.get(topicName);
    if (topic == null) {
      LOG.debug("creating topic {}.", topicName);
      _topics.put(topicName, topic = new HashMap<String, List<Item>>());
    }

    if (method.equals("DELETE")) {
      LOG.trace("removing {} from {}.{}", items, topicName, id);
      topic.get(id).removeAll(items);
    }
    else if (method.equals("PATCH")) {
      LOG.trace("adding {} to {}.{}", items, topicName, id);
      topic.get(id).addAll(items);
    }
    else if (method.equals("PUT")) {
      LOG.trace("creating {}.{} with {}", topicName, id, items);
      topic.put(id, items);
    }

    LOG.trace("topics after mutate: {}", _topics);
  }

  private Map<String, Map<String, List<Item>>> _topics;
  private static final Logger LOG = getLogger();
}
