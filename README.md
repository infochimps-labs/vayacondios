# Vayacondios

Vayacondios is a server-client program designed to make it simple to
collect and centralize information and metrics from a large number of
disparate sources from multiple application domains.

Vayacondios has the following design goals:

The client is simple enough to use in a shell script and the server is
performant enough to support ubiquitous use across a large
installation with many clients.

* *Decentralized* -- Any client can dispatch stashes or events from anywhere
* *Dynamic* -- No data types or schemas need to be created in advance
* *Ubiquitous* -- Clients require minimal dependencies because the API is simple to use and access
* *Simple* -- Clients can write data in whatever way is natural for them
* *Scalable* -- Server and storage can be scaled horizontally to allow for ever-increasing loads
* *Fast* -- No client should have to worry that sending data to Vayacondios will affect its performance

The basic objects of Vayacondios are **stash** and the **event**:

* a **stash** is an "object", a "configuration", or "setting" designed to be shared among many services
* an **event** is a "fact", "measurement", or "metric" announced by an arbitrary service, possibly related to some stash

Stashes and events are each documents which can contain arbitrary
JSON-serializable data: hashes/maps/dictionarys, arrays/lists,
strings, numbers, floats, null, &c.

The client and server communicate over a RESTful, HTTP-based API which
speaks JSON.

See also [Coda Hale's metrics](https://github.com/codahale/metrics/).

<a name="architecture" />
## Architecture

<a name="architecture-database" />
### Database

Vayacondios stores all its data in a database.  Access to the database
within Vayacondios is strictly contained within model classes within
`lib/vayacondios/server/models`.  This is so that the backend database
can one day be changed easily without affecting the rest of the
application.

[MongoDB](http://www.mongodb.org/) is currently the only supported
database.  MongoDB is a natural choice because it exposes atomic query
primitives which map very closely to the operations exposed by the
Vayacondios API.

<a name="architecture-server" />
### Server

The Vayacondios server process is a
[Goliath](https://github.com/postrank-labs/goliath) web server which
implements the Vayacondios API over HTTP using JSON.

A single server process can easily handle hundreds of client requests
per second.  Multiple Vayacondios servers can easily be deployed
behind a load-balancer.

Each running server process reads and writes all its data in a single
MongoDB database specified at runtime.

<a name="architecture-client" />
### Client

Clients communicate with the Vayacondios server via the HTTP API it
exposes.  This makes it extremely simply for applications in any
language to communicate with the server.

Vayacondios comes with several clients:

* a Ruby-language client (`Vayacondios::HttpClient`)
* a Java-language client (`com.infochimps.vayacondios.HTTPClient`)
* a command-line client (the `vcd` program)

The Ruby-language client and the command-line client are bundled with
the `vayacondios-client` Ruby gem.  The Java-language client is part
of the `com.infochimps.vayacondios` package.

<a name="datamodel" />
## Data Model

Vayacondios uses a two-level hierarchical data model to organize
events and stashes.

The top-level is the **organization**.  Data from multiple
organizations is stored together but accessed separately by a running
Vayacondios server.  An organization could be the name of a user,
workgroup, application, or service using Vayacondios.

The next level is the **topic**.  Each topic within Vayacondios has a
single stash and can have multiple events.  An "object" like a server,
a database, an application, a service, or a user maps to the concept
of "topic".

Topics and organizations are strings which can only contain letters,
digits, underscores, periods, and hypens, though periods cannot be the
first or last character.  Organizations cannot begin with the string
`system.`.

<a name="datamodel-events" />
### Events

Events belong to a topic within an organization.  Each event
additionally has

* an ID which is automatically set by the server to a random, unique value if none is provided when the event is announced.  Provided IDs cannot contain periods or dollar signs.
* a timestamp which is automatically set by the server to the current UTC time if none is provided when the event is announced.  Provided timestamps will attempt to be parsed either from a string or from an integer UNIX timestamp.
* arbitrary key/value data.  Keys cannot contain periods or dollar signs.

Events are used for storing facts, measurements, metrics, errors,
occurrences, &c.  If you anticipate wanting to see a time series or a
histogram of a certain kind of data then you should consider writing
that data into Vayacondios as events on some topic.

Events are stored in MongoDB in a collection named after their
organization and topic: an event on the `ci` topic for the `example`
organization would be stored in the MongoDB collection
`example.ci.events`.  The ID of the event, whether auto-generated by
the server or specified by the client, will be used as the `_id` field
of the resulting document within this collection.

Here are some examples of data that it would make sense to store as
events (in JSON format):

* the output of a build from a CI system might be written to topic `ci`
```json
{
  "environment": "Jenkins CI v. 1.519",
  "project": {
    "name":    "website",
	"version": "0b4d99ded50a19e495d2472477bbb0784d8a18d8",
    "url":     "https://github.com/mycompany/website.git",
  },
  "build": {
    "time":   182,
	"status": "success"
  },
  "test": {
    "time":   97,
	"ran":    102,
	"passed": 102,
	"failed": 0
  }
}  
```
* an intrusion event picked up by the firewall might be written to topic `firewall.intrusions`
```json
{
  "ip":     "74.210.29.117",
  "port":   22,
  "type":   "ssh",
  "reason": "blacklisted"
}
```
* some performance statistics for a running server might be written topic `phoenix.servers.webserver-16`
```json
{
  "data_center": "Phoenix",
  "rack":        "14",
  "server":      "webserver-16",
  "cpu": {
    user:   3.17,
	nice:   0.01,
	system: 0.27,
	iowait: 0.18,
	steal:  0.00,
	idle:   96.38
  },
  "mem": {
    "total": 12304632,
	"used":  10335900,
	"free":  1968732
  },
  "net": {
    "out": 2.25,
	"in":  10.28,
  },
  "disk": {
    "write": 16.182,
	"read":  0.11
  }
```
<a name="datamodel-stashes" />
### Stashes

Stashes belong to a topic within an organization.  Each stash
additionally has arbitrary key/value data that it can store.  Keys
cannot contain dollar signs or periods.

Stashes are used for storing objects, configuration, settings, &c.  If
you anticipate wanting to lookup a value by name then you should
consider writing that data into Vayacondios as (or within) a stash on
some topic.

The names of top-level keys within a stash can be used as the "ID"
when retrieving/setting/deleting values via the API.

Stashes are stored in MongoDB in a collection named after their
organization: a stash for the `example` organization would be stored
in the MongoDB collection `example.stash`.  The topic of the stash
will be used as the `_id` field of the resulting document within this
collection.

Here are some examples of data that it would make sense to store as
stashes (in JSON format):

* a collection of projects to run through a CI system might be stored on topic `ci`
```json
{
  "projects": {
    {
	  "name": "website",
	  "url":  "https://github.com/mycompany/website.git",
	},
    {
	  "name": "client_tool",
	  "url":  "https://github.com/mycompany/client_tool.git",
	},
	...
  }
}
```
* firewall settings might be stored on topic `firewall`
```json
{
  "firewall": {
    "rules": [
	  {
	    "range":    "0.0.0.0",
		"port":     80,
		"protocol": "tcp"
      },
	  {
	    "range":    "10.0.0.0",
		"port";     22,
		"protocol": "ssh"
	  }
	]
  }
}
```
* a mapping of servers within some data center might be stored on topic `data_centers.phoenix`
```json
{
  "name":     "PHX",
  "location": "Phoenix, AZ",
  "servers": [
    "webserver-0",
	"webserver-1",
	"webserver-2",
	...
  ]
}
```

<a name="installation" />
## Installation & Configuration

<a name="installation-database" />
## Database

Vayacondios server depends on a database to store all its data.
Currently, only MongoDB is supported: here are some
[installation instructions](http://docs.mongodb.org/manual/installation/).

<a name="installation-server" />
## Server

Vayacondios server is distributed via Rubygems:

```
$ sudo gem install vayacondios-server
```

Once installed, you can launch a copy of the server from the
command-line running locally on port 9000:
```
$ vcd-server --verbose --stdout
```

Ports, logging, the location of MongoDB, and much more can be
configured via command-line options.  Try `vcd-server --help` for more
details.

<a name="installation-client" />
## Client

The server exposes its API via HTTP so all sorts of clients can talk
to Vayacondios server.  Most simply, a command like

```
$ curl -X POST http://localhost:9000/v2/my_organization/event/some_topic -d '{"event": "data"}'
```

will work "right out of the box".

You can also install some pre-written clients that are aware of the
Vayacondios API.

<a name="installation-client-cli" />
### Command-Line

The `vcd` command-line client is installed via Rubygems:

```
$ sudo gem install vayacondios-client
```

You can now run the `vcd` program.  The equivalent to the above `curl`
command would be

```
$ vcd announce 'some_topic' '{"event": "data"}'
```

The `vcd` program looks for its configuration (where is the
Vayacondios server?  what organization am I in?) in the files
`/etc/vayacondios/vayacondios.yml` and `~/.vayacondios.yml`.  The
following can be put in either location to customize the behavior of
`vcd` for a given server or user.

```yml
---
host: vcd.example.com
port: 9000
organization: my_company
```

<a name="installation-client-ruby" />
### Ruby Client

A Ruby client is also avialable via Rubygems:

```
$ sudo gem install vayacondios-client
```

You can now use the `Vayacondios::HttpClient` class in your code:

```ruby
require 'vayacondios-client'
client = Vayacondios::HttpClient.new(organization: 'my_company')
client.announce('some_topic', foo: 'bar')
```

The Ruby client exposes several API requests as named methods (like
`announce` above, which maps to a <a
href="#api-events-announce">announce event</a> API endpoint).

<a name="installation-client-java" />
### Java Client

A Java client is also available.  Put the following into your
`pom.xml`:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  ...
  <repositories>
    ...
    <repository>
      <id>infochimps.releases</id>
      <name>Infochimps Internal Repository</name>
      <url>https://s3.amazonaws.com/artifacts.chimpy.us/maven-s3p/releases</url>
    </repository>
	...
  </repositories>
  ...
  <dependencies>
    ...
    <dependency>
      <groupId>com.infochimps</groupId>
      <artifactId>vayacondios</artifactId>
      <version>2.0.0</version>
    </dependency>
	...
  </dependencies>
  ...
</project>  
```

You can now use the `com.infochimps.vayacondios.HTTPClient` class in
your code:

```java
import com.infochimps.vayacondios.VayacondiosClient;
import com.infochimps.vayacondios.HTTPClient;

class public HelloVayacondios {
  public static void main(String[] args) throws Exception {
    VayacondiosClient client = new HTTPClient("my_organization");
	Map event = new HashMap();
	event.put("foo", "bar");
	client.announce("my_topic", event);
	Thread.sleep(50) // ensures async HTTP request finishes
    client.close();
  }
}
```

The Java client exposes several API requests as named methods (like
`announce` above, which maps to a <a
href="#api-events-announce">announce event</a> API endpoint).

<a name="api" />
## API

The following describes each HTTP endpoint exposed by the Vayacondios
server:

<a name="api-events" />
### Events

<a name="api-events-announce" />
#### Announce a new event

Method: `POST`
Path:   `/v2/ORGANIZATION/event/TOPIC`
Action: Stores a new event with an auto-generated ID

Method: `POST`
Path:   `/v2/ORGANIZATION/event/TOPIC/ID`
Action: Stores/overwrites a new event with the given ID

| Parameter | Description                    | Default      | Example Values                           |
| --------- | ------------------------------ | ------------ | ---------------------------------------- |
| time      | Set the timestamp of the event | current time |`2013-06-20 16:20:48 -0500`, `1371763237` |

All other key/value in the request body will be stored as data for the
event.

<a name="api-events-get" />
#### Get an existing event

Method: `GET`
Path:   `/v2/ORGANIZATION/event/TOPIC/ID`
Action: Retrieve an existing event given its ID

<a name="api-events-search" />
#### Search for events

Method: `GET`
Path:   `/v2/ORGANIZATION/events/TOPIC`
Action: Search for events on the given topic.

| Parameter | Description                                  | Default              | Example Values                                         |
| --------- | -------------------------------------------- | -------------------- | ------------------------------------------------------ |
| from      | Occurred after this time                     | 1 hour ago           | `2013-06-20 Thu 00:00:00 -0500`, 1371704400            |
| upto      | Occurred before this time                    | current time         | `2013-06-20 Thu 23:59:59 -0500`, 1371790799            |
| limit     | Return up to this many events                | 50                   | 100, 200                                               |
| fields    | Return only these fields from the event body | all fields           | `["account_id", "ip_address"]`                         |
| sort      | Sort returned events by this field           | descending by time   | `["time", "ascending"]`, `["ip_address", "ascending"]` |

All other key/value in the request body will be used as conditions
that the event body must match.

<a name="api-stashes" />
### Stashes

<a name="api-stashes-set" />
#### Set a stashed value

Method: `POST`
Path:   `/v2/ORGANIZATION/stash/TOPIC`
Action: Overwrites the stash with the given topic.

Method: `POST`
Path:   `/v2/ORGANIZATION/stash/TOPIC/ID`
Action: Overwrites the ID field of the stash with the given topic.

Method: `PUT`
Path:   `/v2/ORGANIZATION/stash/TOPIC`
Action: Merges new data into the stash with the given topic.

Method: `PUT`
Path:   `/v2/ORGANIZATION/stash/TOPIC/ID`
Action: Merges new data into the ID field of the stash with the given topic.

All other key/value in the request body will be stored as data for the
event.

<a name="api-stashes-get" />
#### Get a stashed value

Method: `GET`
Path:   `/v2/ORGANIZATION/stash/TOPIC`
Action: Retrieve the stash with the given topic.

Method: `GET`
Path:   `/v2/ORGANIZATION/stash/TOPIC/ID`
Action: Retrieve the ID field of the stash with the given topic.

<a name="api-stashes-delete" />
#### Delete a stashed value

Method: `DELETE`
Path:   `/v2/ORGANIZATION/stash/TOPIC`
Action: Delete the stash with the given topic.

Method: `DELETE`
Path:   `/v2/ORGANIZATION/stash/TOPIC/ID`
Action: Delete the ID field of the stash with the given topic.

<a name="api-stashes-search" />
#### Search for stashes

Method: `GET`
Path:   `/v2/ORGANIZATION/stashes`
Action: Search for stashes.

| Parameter | Description                                  | Default              | Example Values                 |
| --------- | -------------------------------------------- | -------------------- | ------------------------------ |
| limit     | Return up to this many stashes               | 50                   | 100, 200                       |
| sort      | Sort returned stashes by this field          | ascending by topic   | `["ip_address", "ascending"]`  |

All other key/value in the request body will be used as conditions
that the stash's body must match.

### Copyright

Copyright (c) 2011 - 2013 Infochimps. See [LICENSE.md](LICENSE.md) for further details.
