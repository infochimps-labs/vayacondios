import com.infochimps.vayacondios.Organization;
import com.infochimps.vayacondios.VayacondiosClient;
import com.infochimps.vayacondios.ItemSets;
import static com.infochimps.vayacondios.ItemSets.Item;
import static com.infochimps.vayacondios.ItemSets.ItemSet;

import java.io.*;
import java.util.*;

public class ItemSetTest {
  private static final int VCD_PORT = 8000;

  public static void main(String argv[]) throws IOException {
    // Instantiate a new Vayacondios client.
    VayacondiosClient client = new VayacondiosClient("localhost", VCD_PORT);

    // Organizations can allow for testing and multiple environments
    // (staging, development).
    Organization org = client.organization("test");

    // At the moment, only the itemsets protocol is supported via a
    // Java API.
    ItemSets isets = org.itemsets();

    List<Item> foobar = Arrays.asList(new Item("foo"), new Item("bar"));

    // All of the following are equivalent ways to clobber the itemset
    // at topic my_topic and id my_id, replacing it with the items
    // "foo" and "bar." The first and second exist to avoid
    // instantiating new objects repeatedly when a code path must
    // access many different topics and ids.
    isets                                   .create(foobar, "my_topic", "my_id");
    isets.topic("my_topic")                 .create(foobar,             "my_id");
    isets.topic("my_topic").itemSet("my_id").create(foobar                     );

    List<Item> fetched;

    // Similarly, these are all equivalent ways to fetch items.
    fetched = isets                                   .fetch("my_topic", "my_id");
    fetched = isets.topic("my_topic")                 .fetch(            "my_id");
    fetched = isets.topic("my_topic").itemSet("my_id").fetch(                   );

    ItemSet iset = isets.topic("my_topic").itemSet("my_id");

    // foo and bar will be printed, along with their types: STRING
    System.out.println("fetched items: " + fetched);

    List<Item> bazqux = Arrays.asList(new Item("baz"), new Item("qux"));

    // Updating an itemset with a list of items ensures the presence
    // in the itemset of all of the items in the specified list.
    isets                                   .update(bazqux, "my_topic", "my_id");
    isets.topic("my_topic")                 .update(bazqux,             "my_id");
    isets.topic("my_topic").itemSet("my_id").update(bazqux                     );

    // foo, bar, baz, and qux will all be printed.
    System.out.println("after update: " + iset.fetch());

    List<Item> barbaz = Arrays.asList(new Item("bar"), new Item("baz"));

    // Updating an itemset with a list of items ensures the presence
    // in the itemset of all of the items in the specified list.
    isets                                   .remove(barbaz, "my_topic", "my_id");
    isets.topic("my_topic")                 .remove(barbaz,             "my_id");
    isets.topic("my_topic").itemSet("my_id").remove(barbaz                     );

    // foo and qux will now be printed
    System.out.println("after removing: " + iset.fetch());

    // Create an empty itemset to effectively delete it.
    iset.create(Collections.EMPTY_LIST);

    // foo and qux will now be printed
    System.out.println("after deletion: " + iset.fetch());
  }
}
