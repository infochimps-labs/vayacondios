package com.infochimps.vayacondios;

import com.infochimps.vayacondios.VayacondiosClient;

import static com.infochimps.util.CurrentClass.getLogger;

import com.infochimps.vayacondios.MemoryVCDShim;
import static com.infochimps.vayacondios.ItemSets.Item;
import static com.infochimps.vayacondios.ItemSets.ItemSet;
import com.infochimps.vayacondios.ItemSets;

import java.io.IOException;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import static org.junit.Assert.assertEquals;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.Ignore;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

import org.slf4j.Logger;

@RunWith(JUnit4.class)
  public class TestVayacondiosInMemory {
    @Before
      public void setup() {
      _itemSets = new VayacondiosClient("localhost", VCD_PORT).
        organization("org").
        itemsets(new MemoryVCDShim());
    }

    @Test
    public void testInMemVCD() throws Exception {
      create("foo", "baz", "bar", "bing");
      assertEquals(buildItemList("foo", "baz", "bar", "bing"), fetch());

      update("biff");
      assertEquals(buildItemList("foo", "baz", "bar", "bing", "biff"), fetch());

      remove("biff", "bar");
      assertEquals(buildItemList("foo", "baz", "bing"), fetch());
    }

    private ItemSets itemSets() {
      return _itemSets;
    }

    private static List<Item> buildItemList(String... itemNames) {
      List<Item> result = new ArrayList<Item>();
      for (String s : itemNames) result.add(new Item(s));
      return result;
    }

    private List<Item> fetch() throws IOException {
      return itemSets().fetch("topic", "id");
    }

    private void create(String... items) throws IOException {
      itemSets().create("topic", "id", buildItemList(items));
    }

    private void remove(String... items) throws IOException {
      itemSets().remove("topic", "id", buildItemList(items));
    }

    private void update(String... items) throws IOException {
      itemSets().update("topic", "id", buildItemList(items));
    }

    private static final int VCD_PORT = 8000;
    private static final Logger LOG = getLogger();
    private ItemSets _itemSets;
  }