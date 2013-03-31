# Vaya con Dios

## Warning

Some of the documentation on this page is for legacy versions of
Vayacondios. Until this document is updated, please see the specs for
the Ruby code or compile the javadocs for the Java API.

> "Data goes in. The right thing happens."

Simple enough to use in a shell script, performant enough to use everywhere.

You can chuck the following into Vaya con Dios from Ruby, the shell, over HTTP, or in a repeated polling loop:

* *value*   -- 'there are 3 cups of coffee remaining':
* *timing*  -- 'this response took 100ms'
* *count*   -- 'I just served a 404 response code'
* *fact*    -- 'here's everything to know about the coffee machine: `{"cups_remaining":3,"uptime":127,room:"hyrule"}`' -- an arbitrary JSON hash

### Design goals

* *Decentralized* -- Any (authorized) system can dispatch facts or metrics using an arbitrary namespace and schema. Nothing needs to be created in advance.
* *Bulletproof* -- UDP clients will never fail because of network loss or timeout.
* *Fast* -- UDP clients are non-blocking and happily dispatch thousands of requests per second.
* *Minimal Dependency* -- Ruby clients uses nothing outside of the standard libraries.
* *Ubiquitous* -- Can send facts from the shell (with nothing besides `curl`)
* *writes are simple, reads are clever* -- A writer gets to chuck things in according to its conception of the world.

See also [Coda Hale's metrics](https://github.com/codahale/metrics/).

## Namespacing

The first path segment defines a collection, and the remainder defines a [materialized path](http://www.mongodb.org/display/DOCS/Trees+in+MongoDB#TreesinMongoDB-MaterializedPaths%28FullPathinEachNode%29).
All hashes within a given path should always have the same structure. Writes to an overlapping key will overwrite.

A full Vaya con Dios path is broken down into specific segments.

`/:organization/(event|config)/:topic.format`

* `:organization` is the top level collection that all info is contained in.
* `(event|config)` changes the context of the message. Events are timestamped and scope destructive. Config is merged with the current configuration.
* `topic` is the materialized path we referred to that specifies its unique location.
* `format` will change the serialization format for the data. Only JSON is currently supported.

### Events

Events are the primary piece of information stored. An event is anything that happened that you'd want to write down.

For example a `POST` to `http://vayacondios.whatever.com/v1/code/commit` with the
```
{
  "_id":     "f93f2f08a0e39648fe64",     # commit SHA as unique id
  "_path":   "code.commit",              # materialized path
  "_ts":     "20110614104817",           # utc flat time
  "repo":    "infochimps/wukong"
  "message": "...",
  "lines":   69,
  "author":  "mrflip"
}
```

Will write the hash as shown into the `code` collection. Vaya con Dios fills in the _path always, and the _id and _ts if missing. This can be queried with path of "^commit/infochimps" or "^commit/.*".

The hash will contain:

* `_id` -- unique _id
* `_ts` -- timestamp, set if blank
* `_path` -- `name.spaced.path.fact_name`, omits the collection part


### Writes

* value
* count
* timing
* fact

`echo 'bob.dobolina.mr.bob.dobolina:320|ms:320' | netcat -c -u 127.0.0.1 8125`

`http://vayacondios:9000/bob/dobolina/mr/bob/dobolina?_count=1`

`http://vayacondios:9000/bob/dobolina/mr/bob/dobolina?_count=1&_sampling=0.1`

`http://vayacondios:9000/bob/dobolina/mr/bob/dobolina?_timing=320`

### also

* Path components must be ASCII strings matching `[a-z][a-z0-9_]+` -- that is,  start with [a-z] and contain only lowercase alphanumeric, underscore, or hyphen. Components starting with a '_' have reserved meanings. The only valid underscored fields that a request can fill in are _id, _ts and _path.

* Vaya con Dios reserves the right to read and write paths in `/vayacondios`, and the details of those paths will be documented; it will never read or write other paths unless explicitly asked to.

* tree_merge rules:

  - hash1 + hash = hash1.merge(hash)
  - arr1 + arr2  = arr1 + arr2
  - val1 + val2  = val2

  - hsh1 + nil   = hsh1
  - arr1 + nil   = arr1
  - val1 + nil   = val1

  - nil  + hs## = hsh2
  - nil  + arr2  = arr2
  - nil  + val2  = val2

  - otherwise, exception

  types: Hash, Array, String, Time, Integer, Float, Nil

    mongo: string, int, double, boolean, date, bytearray, object, array, others
    couch: string,number,boolean,array,object

#### add (set? send?)

GET  http://vayacondios:9099/f/{clxn}/{arbitrary/name/space}.{ext}?auth=token&query=predicate

  db.collection(collection).save


get


#### get

POST http://vayacondios:9099/f/arbitrary/name/space  with JSON body

#### Increment

#### Add to set

what do we need to provide the 'I got next' feature (to distribute resources uniquely from a set)?

#### Auth

`/vayacondios/_auth/` holds one hash giving public key.
* walk down the hash until you see _tok
* can only auth at first or second level?
* or by wildcard?
* access is read or read_write; by default allows read_write

## Others

GET latest
GET all
GET next

## Configuration

All organizations have a special topic called, "config" that allows for storage and retrieval of configuration data via standard [CRUD requests](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete).

### Writing config data

A `POST` request can be made to a full URL such as: `http://vayacondios:9000/organization/topic/some/deep/key`

Vaya con Dios stores configuration data in special collections (`"#{organization}.config"`). The topic acts as the primary key while `/some/deep/key` acts as a materialized path for selection.

## Notes

### When to use HTTP vs UDP

#### HTTP is connectionful

* you get acknowledgement that a metric was recorded (this is good).
* if the network is down, your code will break (this is bad). (Well, usually. For some accounting and auditing metrics one might rather serve nothing at all than something unrecorded. Vayacondios doesn't address this use case.)

#### UDP has Packet Size limitations

If you're using UDP for facts, you need to be *very* careful about payload size.

From the [EventMachine docs](http://eventmachine.rubyforge.org/EventMachine/Connection.html#M000298)

> You may not send an arbitrarily-large data packet because your operating system will enforce a platform-specific limit on the size of the outbound packet. (Your kernel will respond in a platform-specific way if you send an overlarge packet: some will send a truncated packet, some will complain, and some will silently drop your request). On LANs, it’s usually OK to send datagrams up to about 4000 bytes in length, but to be really safe, send messages smaller than the Ethernet-packet size (typically about 1400 bytes). Some very restrictive WANs will either drop or truncate packets larger than about 500 bytes.

## Colophon

### Contributing to vayacondios

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

### Copyright

Copyright (c) 2011, 2012 Infochimps. See [LICENSE.md](LICENSE.md) for further details.
