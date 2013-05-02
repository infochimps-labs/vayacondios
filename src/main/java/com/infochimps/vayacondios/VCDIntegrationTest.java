package com.infochimps.vayacondios;

import com.infochimps.vayacondios.VayacondiosClient;

import static com.infochimps.util.CurrentClass.getLogger;

import static com.infochimps.vayacondios.ItemSets.Item;
import static com.infochimps.vayacondios.ItemSets.ItemSet;
import com.infochimps.vayacondios.ItemSets;

import java.io.IOException;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.slf4j.Logger;

public class VCDIntegrationTest {
  private static final int VCD_PORT = 8000;
  private static final Logger LOG = getLogger();

  private static ItemSets itemSets() {
    return new VayacondiosClient("localhost", VCD_PORT).
      organization("org").
      itemsets();
  }

  private static List<Item> buildItemList(String items[]) {
    List<Item> result = new ArrayList<Item>();
    for (String s : items) result.add(new Item(s));
    return result;
  }

  private static List<String> getStrings(List<Item> items) {
    List<String> result = new ArrayList<String>();
    for (Item i : items) result.add(i.getAsString());
    return result;
  }

  private static List<String> fetch() throws IOException {
    return getStrings(itemSets().fetch("topic", "id"));
  }

  private static void create(String... items) throws IOException {
    itemSets().create("topic", "id", buildItemList(items));
  }

  private static void remove(String... items) throws IOException {
    itemSets().remove("topic", "id", buildItemList(items));
  }

  private static void update(String... items) throws IOException {
    itemSets().update("topic", "id", buildItemList(items));
  }

  private static void assertEquals(String... expectedArr)
    throws IOException {
    List<String> items = fetch();
    List<String> copy = new ArrayList<String>();
    List<String> expected = Arrays.asList(expectedArr);

    if (!items.containsAll(expected)) {
      copy = new ArrayList(); copy.addAll(expected);
      LOG.trace("removing items. copy change? " + copy.removeAll(items));
      System.out.println("\033[31mFAIL\033[0m: expected but absent: " + copy);
    } else
      System.out.println("\033[32mSUCCESS\033[0m: all expected items present");
    if (!expected.containsAll(items)) {
      copy = new ArrayList(); copy.addAll(items);
      LOG.trace("removing items. copy change? " + copy.removeAll(expected));
      System.out.println("\033[31mFAIL\033[0m: unexpected and present: " + copy);
    } else
      System.out.println("\033[32mSUCCESS\033[0m: no unexpected items present");
  }

  public static void main(String argv[]) {
    System.out.println("*** If Vayacondios is not running on port " + VCD_PORT + ", " +
                       "this will fail. ***");
    System.out.println("Running Vayacondios integration test...");

    try {
      create("foo", "baz", "bar", "bing");
      assertEquals("foo", "baz", "bar", "bing");

      update("biff");
      assertEquals("foo", "baz", "bar", "bing", "biff");

      remove("biff", "bar");
      assertEquals("foo", "baz", "bing");
      
      System.out.println("Integration test complete.");
    } catch (Exception ex) {
      ex.printStackTrace();
    }
  }
}