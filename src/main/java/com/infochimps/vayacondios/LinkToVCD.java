package com.infochimps.vayacondios;

import java.util.List;
import java.io.IOException;
import static com.infochimps.vayacondios.ItemSets.Item;

public abstract class LinkToVCD {
  public abstract List<Item> fetch(String topic, String id) throws IOException;
  public abstract void mutate(String method,
                              String topic,
                              String id,
                              List<Item> items) throws IOException;

  protected ItemSets getParent() { return _parent; }
  public void setParent(ItemSets parent) { _parent = parent; }

  private ItemSets _parent;
}
