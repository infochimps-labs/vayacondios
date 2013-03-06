package com.infochimps.vayacondios;

import com.infochimps.vayacondios.VayacondiosClient;

import static com.infochimps.util.CurrentClass.getLogger;

import static com.infochimps.vayacondios.ItemSets.Item;
import static com.infochimps.vayacondios.ItemSets.ItemSet;

import java.io.IOException;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.slf4j.Logger;

public class VCDIntegrationTest {
  private static final int VCD_PORT = 8000;
  private static final Logger LOG = getLogger();

  private static ItemSet newSet() {
    return new VayacondiosClient("localhost", VCD_PORT).
      organization("org").
      itemsets().
      topic("topic").
      itemSet("id");
  }

  private static void assertEquals(String... expectedStringArr)
    throws IOException {
    List<Item> items = newSet().fetch();
    List<Item> expectedItems = new ArrayList();
    List<Item> copy;

    for (String exp : expectedStringArr) expectedItems.add(new Item(exp));

    if (!items.containsAll(expectedItems)) {
      copy = new ArrayList(); copy.addAll(expectedItems);
      LOG.trace("removing items. copy change? " + copy.removeAll(items));
      System.out.println("\033[31mFAIL\033[0m: expected but absent: " + copy);
    }
    if (!expectedItems.containsAll(items)) {
      copy = new ArrayList(); copy.addAll(items);
      LOG.trace("removing items. copy change? " + copy.removeAll(expectedItems));
      System.out.println("\033[31mFAIL\033[0m: unexpected and present: " + copy);
    }
  }

  public static void main(String argv[]) {
    System.out.println("*** If Vayacondios is not running on port " + VCD_PORT + ", " +
		       "this will fail. ***");
    System.out.println("Running Vayacondios integration test...");

    try {
      newSet().create(Arrays.asList(new Item("foo"), new Item("baz"), new Item("bar"), new Item("bing")));
      assertEquals("foo", "baz", "bar", "bing");
      newSet().update(Arrays.asList(new Item("biff")));
      assertEquals("foo", "baz", "bar", "bing", "biff");
      newSet().remove(Arrays.asList(new Item("biff"), new Item("bar")));
      assertEquals("foo", "baz", "bing");
      
      System.out.println("Integration test complete.");
    } catch (Exception ex) {
      ex.printStackTrace();
    }
  }
}