I'm trying to figure out a unified data model for broham and statsd/graphite.

For broham, I propose that the first path segment defines a collection, and the remainder defines a [materialized path.](http://www.mongodb.org/display/DOCS/Trees+in+MongoDB#TreesinMongoDB-MaterializedPaths%28FullPathinEachNode%29)
All hashes within a given colxn.path should always have the same structure (so, don't record a george download and a george signup in the same scope).

For example a POST to http://broham.whatever.com/code/commit with

```javascript
  { "_id":     "f93f2f08a0e39648fe64",     # commit SHA as unique id 
    "_path":   "code/commit",              # materialized path
    "_ts":     "20110614104817",           # utc flat time
    "repo":    "infochimps/wukong"
    "message": "...",
    "lines":   69,
    "author":  "mrflip", }
```

will write the hash as shown into the `code` collection. Brocephalus fills in the _path always, and the _id and _ts if missing. This can be queried with path of "^commit/infochimps" or "^commit/.*" or

Hash will hold:

* `_id`           unique _id
* `_ts`           timestamp, set if blank
* `_path`         `name.spaced.path.fact_name`, omits the collection part

The only _underscored fields that request can fill in are _id, _ts and _path. All others are scrubbed (?). All other fields must be `[a-z][a-z0-9_]+` (lowercase,starts with a letter).

---------------------------------------------------------------------------

### noodling about metrics

broham facts:

```
* code.commit                   {repo,message,lines,author}
* code.deploy                   {cluster,repo,environment,SHA,cluster-facet-idx,instance_id}
* hackboxen.run                 {runtime,hackbox,icss_files,data_assets,...}
* hackboxen.hadoop              {job_name,job_id,cluster,nodes,machine_size,runtime,input,output,map_tasks,reduce_tasks,counters,bytes_read,outcome}
* troop.{target}                publishing to george, s3, mysql, es, etc.
* george.{item}                 info on a new registered * user, dataset, download, purchase, unique, pageview, or supplier signup
* highrise.note                 {email,case,subject,contact}
* highrise.contact              {name,email,phone}
* zendesk.email                 {email,subject,tags}
* monitor.system                {processes,swap,memory,cpu,disk_free.drive.path}
* scraper.tw_api                summary of scrape this hour.

* chef.{nodes,roles,cookbooks}
* fog.servers                   { cloud id created_at state ip_address private_ip_address dns_name nodename ... }
* google_analytics.{}
* {simple.dashboard}            {hash representing form results}
```

path  => _id handle
query => payload

posts against path is idempotent
can specify _next

how do we handle tree leaves vs. branches (files vs dirs)


graphite metrics:

* `buzzkill.em.latency.prehensile.apinode-5`
* `buzzkill.em.connection_count.prehensile.apinode-5`
* `buzzkill.req.{200,404,...}.{timing,count}`
* `buzzkill.req.error.{missing_apikey,request_failed,...}`
* `apeyeye.req.{200,404,...}.{timing,count}`
* `apeyeye.req.social.network.tw.influence.trstrank`
* `apeyeye.endpoint_req.name.space.protocol.endpoint`
* `scraper.tw_api.reqs.{all,200,401,404,502,503}`
* `scraper.tw_api.mb`
* `scraper.tw_search.reqs.{all,200,401,404,502,503}`
* `scraper.tw_search`
* `scraper.tw_parsed.{user,tweet,geo,...}`
* `monitor.system.{machine_name}.{processes,swap,memory,cpu,disk_free.drive.path}`
* `george.{item}.count`                               count of registered * `users, datasets, downloads, purchases, uniques, pageviews, supplier signups
* `george-ext.render.timing`                          something from the outside world

* "materialized paths":http://www.mongodb.org/display/DOCS/Trees+in+MongoDB#TreesinMongoDB-MaterializedPaths%28FullPathinEachNode%29
* see also: [Modeling a Tree in a Document Database](http://seancribbs.com/tech/2009/09/28/modeling-a-tree-in-a-document-database)



