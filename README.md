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
```
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
```
{
  "ip":     "74.210.29.117",
  "port":   22,
  "type":   "ssh",
  "reason": "blacklisted"
}
```
* some performance statistics for a running server might be written topic `phoenix.servers.webserver-16`
```
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
```
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
```
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
```
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
### Database

Vayacondios server depends on a database to store all its data.
Currently, only MongoDB is supported: here are some
[installation instructions](http://docs.mongodb.org/manual/installation/).

<a name="installation-server" />
### Server

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
### Client

The server exposes its API via HTTP so all sorts of clients can talk
to Vayacondios server.  Most simply, a command like

```
$ curl -X POST http://localhost:9000/v2/my_organization/event/some_topic -d '{"event": "data"}'
```

will work "right out of the box".

You can also install some pre-written clients that are aware of the
Vayacondios API.

<a name="installation-client-cli" />
#### Command-Line

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
#### Ruby Client

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
#### Java Client

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
## API (v2)

All HTTP endpoints defined by the Vayacondios server API share a
common structure: `/:version/:organization/:type/[:topic]/[:id]/...`

| Parameter    | Required | Definition                            | Examples                              |
| ------------ | -------- |	------------------------------------- | ------------------------------------- |
| version      | required |	Vayacondios API version               | v1, v2 (current)                      |
| organization | required |	Name of organization, service, or app | `security`, `accounting`, `customerX` |
| type         | required |	Request type                          | `event`, `stash`, `events`, `stashes` |
| topic        | varies   |	Topic for event or stash              | `firewall`, `servers.webserver-3`     |
| id           | varies   |	ID of event or field within stash     | `cpu`, `liua38923u2389f`              |

The `version`, `organization`, and `type` parameters are always
required.  Other parameters are required depending on the endpoint.

Vayacondios server only listens for a single value of the top-level
`version` parameter (curently: `v2`). A frontend webserver (Apache,
nginx, &c.) can be used to split traffic to backend Vayacondios
servers running different versions of the Vayacondios API by routing
based on this parameter.

The `type` parameter is fixed and defines the type of a Vayacondios
request: `event`, `stash`, `events`, or `stashes`.

All other parameters are completely free for clients to specify under
the following constraints:

* the `organization` parameter can only contain letters, digits,
  hyphens, and underscores and it must begin with a letter

* the `topic` parameter can only contain letters, digits, hyphens,
  underscores, and periods and it cannot start or end with a period

* the `id` parameter cannot contain the dollar sign or period

The `type`, `organization`, `topic`, and `id` parameter together
constitue the *vayacondios route*.

The *document* is the request body sent to the server with a given
request.  Requests to Vayacondios should have JSON-encoded bodies but
the body can be any JSON datatype: Hash, Array, String, Integer,
Float, Boolean, or `null`.

The *response* is the JSON-encoded response body sent back to the
client from the server.  If an error occurred, in addition to the
appropriate HTTP response code, the response will be a Hash containing
the key `error` with a message detailing the error.

In the case of a record which is not found, the response may be empty
but the HTTP response code will be 404.

In the case of a successful request, the response code will be 200 and
the response body will the requested/written object.

<a name="api-events" />
### Events

A topic within an organization can have many events.

Events are Hash-like data structures which have an associated
timestamp and ID.

Events can be announced, retrieved, and searched.  Events cannot be
updated or deleted, though announcing an event with the same ID as an
existing event overwrites the existing event.

<a name="api-events-announce" />
#### Announce a new event

An event can be created without an ID.  The server will generate a
random, unique ID and include it with the event in the response.  This
is the most common way to write an event.  If you don't intend to ever
retrieve this specific event (as opposed to searching across events)
then this is the right choice.

Events can also be created with an explicit ID. This is less common
but can be useful if your events naturally contain a unique
identifier.

| Method | Path                               | Request | Response | Action                                          | 
| ------ | ---------------------------------- | ------- | -------- | ----------------------------------------------- |
| POST   | /v2/:organization/event/:topic     | Hash    | Hash     | Stores a new event with an auto-generated ID    |
| POST   | /v2/:organization/event/:topic/:id | Hash    | Hash     | Stores/overwrites a new event with the given ID |

All requests to announce a new event accept a Hash-like request body.
Key/value pairs in this request body constitute the body of the event.
The following parameters have special meaning:

| Parameter | Description                    | Default      | Example Values                           |
| --------- | ------------------------------ | ------------ | ---------------------------------------- |
| time      | Set the timestamp of the event | current time |`2013-06-20 16:20:48 -0500`, `1371763237` |

The response body will contain a Hash that is the original request
Hash but with the (possibly auto-generated) ID and timestamp included.

<a name="api-events-get" />
#### Get an existing event

Events can be retrieved if their ID is known.

| Method | Path                               | Request | Response | Action                                          | 
| ------ | ---------------------------------- | ------- | -------- | ----------------------------------------------- |
| GET    | /v2/:organization/event/:topic/:id | N/A     | Hash     | Retrieve an existing event given its ID         |

The response will contain the event Hash if found or will be empty if
not.

<a name="api-events-search" />
#### Search for events

You can search for events matching a query.

| Method | Path                           | Request | Response    | Action                                          | 
| ------ | ------------------------------ | ------- | ----------- | ----------------------------------------------- |
| GET    | /v2/:organization/event/:topic | Hash    | Array<Hash> | Search for events on the given topic.           |

The default behavior (which will occur with an empty request body) is
to return the most recent 50 events on the given `topic` sorted in
descending order by their timestamps.

Each key in the query body will be interpeted as a condition that the
data of each event must match in order to be returned.  Keys with
periods are interpreted as nested fields.  The following parameters
have special meaning and can be used to adjust the time window, number
of returned events, the sort behavior, and the fields within each
event to return:

| Parameter | Description                                  | Default              | Example Values                                         |
| --------- | -------------------------------------------- | -------------------- | ------------------------------------------------------ |
| from      | Occurred after this time                     | 1 hour ago           | `2013-06-20 Thu 00:00:00 -0500`, 1371704400            |
| upto      | Occurred before this time                    | current time         | `2013-06-20 Thu 23:59:59 -0500`, 1371790799            |
| limit     | Return up to this many events                | 50                   | 100, 200                                               |
| fields    | Return only these fields from the event body | all fields           | `["account_id", "ip_address"]`                         |
| sort      | Sort returned events by this field           | descending by time   | `["time", "ascending"]`, `["ip_address", "ascending"]` |
| id        | Regular expression search on event ID        | N/A                  | `sensor-data-.*`, `2013-06-20-.*`                      |

The response will be an Array of the matching events, possibly an
empty Array if no events were found.

<a name="api-stashes" />
### Stashes

A topic within an organization can have a stash.

Stashes are Hash-like data structures.  Each key/value pair with the
stash can be accessed directly by using the name of its key as the ID
in requests.

Stashes can be set, merged, retrieved, searched, and destroyed.

<a name="api-stashes-set" />
#### Set a value

You can set a value for a stash or one of the fields within a stash.
Your value will override whatever value is currently stored for that
stash or for that ID within the stash.

| Method | Path                               | Request | Response | Action                                                     |
| ------ | ---------------------------------- | ------- | -------- | ---------------------------------------------------------- |
| POST   | /v2/:organization/stash/:topic     | Hash    | Hash     | Overwrites the stash with the given topic.                 |
| POST   | /v2/:organization/stash/:topic/:id | varies  | varies   | Overwrites the ID field of the stash with the given topic. |

When setting the stash itself, your value must be Hash-like.  When
setting an ID within a stash, your value can have any datatype.

The response for setting a stash will be the (Hash-like) stash you
just set.  When setting an ID within a stash, the response will be of
the same datatype as the request.

#### Merge a value

You can merge a value for a stash or one of the fields within a stash.

| Method | Path                               | Request | Response | Action                                                      |
| ------ | ---------------------------------- | ------- | -------- | ----------------------------------------------------------- |
| PUT    | /v2/:organization/stash/:topic     | Hash    | Hash     | Merges into the stash with the given topic.                 |
| PUT    | /v2/:organization/stash/:topic/:id | varies  | varies   | Merges into the ID field of the stash with the given topic. |

When merging the stash itself, your value must be Hash-like and will
be merged on top of the existing (Hash-like) stash's value.

When merging one of the ID fields within the stash, your value can
have any datatype and it will be intelligently merged:

* if your value is Hash-like and the existing value is Hash-like , your new value will be merged on top of the existing value
* if your value is Array-like and the existing value is Array-like , your new value will be concatenated to the end of the existing value
* if your value is String-like and the existing value is String-like , your new value will be concatenated to the end of the existing value
* if your value is Numeric-like and the existing value is Numeric-like , your new value will be added to the existing value

The response for merging a stash will be the Hash-like combination of
your old and new value.  The response for merging an ID within a stash
will be of the same type as the request.

<a name="api-stashes-get" />
#### Get a value

You can get the value of an existing stash or one of the fields within
that stash.

| Method | Path                               | Request | Response | Action                                                 |
| ------ | ---------------------------------- | ------- | -------- | ------------------------------------------------------ |
| GET    | /v2/:organization/stash/:topic     | N/A     | Hash     | Return the stash with the given topic.                 |
| GET    | /v2/:organization/stash/:topic/:id | N/A     | varies   | Return the ID field of the stash with the given topic. |

The response for retreiving a stash will be the Hash-like stash while
the response for retreving an ID field within a stash will vary based
on the datatype of that value.

<a name="api-stashes-delete" />
#### Delete a value

You can get delete a stash or one of the fields within a stash.

| Method | Path                               | Request | Response | Action                                                  |
| ------ | ---------------------------------- | ------- | -------- | ------------------------------------------------------- |
| DELETE | /v2/:organization/stash/:topic     | N/A     | Hash     | Deletes the stash with the given topic.                 |
| DELETE | /v2/:organization/stash/:topic/:id | N/A     | Hash     | Deletes the ID field of the stash with the given topic. |

The response for deleting a stash or an ID within a stash will be a
Hash naming the topic (and ID if given in the request) deleted.

<a name="api-stashes-search" />
#### Search for stashes

You can search for stashes.

| Method | Path                        | Request | Response    | Action                                                  |
| ------ | --------------------------- | ------- | --------    | ------------------------------------------------------- |
| GET    | /v2/:organization/stash     | Hash    | Array<Hash> | Search for stashes matching the given query.            |

The default behavior (which will occur with an empty request body) is
to return 50 stashes in sorted in ascending order by their topic.

Each key in the query body will be interpreted as a condition that the
data of each stash must match in order to be returned.  Keys with
periods are interpreted as nested fields.  The following parameters
have special meaning and can be used to adjust the number of returned
stashes and the the sort behavior.


| Parameter | Description                                    | Default              | Example Values                     |
| --------- | ---------------------------------------------- | -------------------- | ---------------------------------- |
| limit     | Return up to this many stashes                 | 50                   | 100, 200                           |
| sort      | Sort returned stashes by this field            | ascending by topic   | `["ip_address", "ascending"]`      |
| topic     | Regular expression search on the stash's topic | N/A                  | `servers-.*`, `firewall\..*\.rule` |

The response will be an Array of the matching stashes, possibly an
empty Array if no events were found.

### Copyright

Copyright (c) 2011 - 2013 Infochimps. See [LICENSE.md](LICENSE.md) for further details.
