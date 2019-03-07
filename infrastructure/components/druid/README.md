# Apache Druid

## Introduction

Druid is a data storage technology designed to real-time and exploratory use cases, such as dashboards.
These are typical [on-Line analytical processing (OLAP)](https://en.wikipedia.org/wiki/Online_analytical_processing) use cases, which are append-heavy and are mostly optimized for read operations, as opposed to on-line transaction processing (OLTP) that deals with 
all kinds of queries (i.e., update, delete, insert).

To this end, OLAP systems rely on a (hyper-)cube structure to organize data, built for instance as projection of an RDBMS relation.
The dimensions of the cube categorize different measures. The main concept behind OLAP is the possibility to organize data hierarchically on each of those dimensions, i.e. to aggregate data on each of the dimensions of the cube, consequently allowing for a 
heterogeneous granularity of the dimensions returned in the result set. 

The Druid project was initiated by [AirBnB](https://medium.com/airbnb-engineering/druid-airbnb-data-platform-601c312f2a4c) to reduce query latency, as opposed to classic MapReduce-based technologies such as Hive, as well as alternative technologies (similarly 
meant to reduce query latency) such as Cloudera Impala which still [suffers](http://druid.io/docs/latest/comparisons/druid-vs-sql-on-hadoop.html) of limits of the Hadoop HDFS concerning data indexing. As mentioned in the [Druid 
paper](http://static.druid.io/docs/druid.pdf), Hadoop works well at storing and accessing large amounts of data, but does however not provide any guarantee on the time necessary to provide a result.

Contrarily, Druid is designed to achieve sub-second latency on ad-hoc analytics queries. 
Specifically, a Druid cluster consists of a Zookeeper for cluster coordination, as well as multiple kinds of nodes (read an intro [here](http://druid.io/docs/latest/design/index.html#what-is-druid)):

* **real-time nodes** - used to ingest and query event streams upon arrival, i.e. they maintain a querable in-memory index of all incoming events; Events are collected from a single endpoint, such as an event bus or message broker, which facilitates both the 
coordination of multiple real-time nodes (by implicitly partitioning the input data stream) and also provides means for offset keeping, which facilitates prompt recovery of real-time nodes upon failure. Persistence to disk is performed either periodically or upon 
reaching a memory limit, namely by converting the in-memory buffer to a column-oriented format and saved as immutable index. These indexes can be loaded back in the buffer for analytical purposes. All locally persisted indexes are also periodically processed and 
aggregated into a `segment`, which can be kept for historical purposes on a secondary persistent storage such as S3 or HDFS. This is commonly refered to as `deep storage`. The three mentioned steps (i.e., ingest, persist, merge) happen seamlessly without any 
service interruption.

* **historical nodes** - used to handle the immutable segments created by the real-time nodes; any historical node is not aware of others but uses zookeeper to announce its presence and mark the segments to load from a local cache (or deep storage if not 
available) and serve, so that others can act accordingly; Once loaded, a segment can be queried on the historical node. Shall a failure prevent Zookeeper from working and recovering, new segments won't be able to be loaded on the nodes, but existing ones will still be 
querable.

* **broker nodes** - used to route queries to real-time and historical nodes, mainly by checking zookeeper for the location of loaded segments; shall be it necessary, broker nodes also aggregate results from both real-time and historical nodes. An LRU cache at 
segment basis is also available on the broker node to minimize requests. The broker, as well as the real-time and historical nodes all expose the same [query API](http://druid.io/docs/latest/querying/querying.html), accessible via a REST interface. Given its 
column-oriented representation, Druid directly supports most types of mathematical aggregations. It does however not support 

* **coordinator nodes** - periodically determines the health of the cluster, as well as manages the cluster configuration and data management policies via a MySQL database and segment metadata information by connecting to Zookeeper;

In Druid a data source is a collection of time-stamped events, partitioned into a set of segments.
As such, segments are the basic unit of parallelism used for replication and distribution.
As mentioned, each segment is a collection of time-stamped rows. The timestamp is the main criteria used for distribution and retention policies, since Druid partitions data sources into time intervals of equal size, mainly depending on the granularity of the 
data. Consequently, each segment is identified by its data source, the time interval that its data represent, as well as a version id, which is increased upon creation, so that newer segments can be easily retrieved to return the latest version of the data.

## About this component
This component installs Druid using the official [Helm Chart](https://github.com/helm/charts/tree/master/incubator/druid).  

Please follow the links hereby for more specific use case:  
* [Setting Minio as S3 storage](https://dzone.com/articles/how-to-configure-druid-to-use-minio-as-deep-storag)
* [Loading data from Kafka](http://druid.io/docs/latest/tutorials/tutorial-kafka.html)
* [Queries](http://druid.io/docs/latest/tutorials/tutorial-query.html)
* [Apache Superset connector](https://superset.incubator.apache.org/druid.html)
* [Tranquility connector](https://github.com/druid-io/tranquility)

