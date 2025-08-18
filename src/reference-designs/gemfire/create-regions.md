# Creating Regions in Tanzu GemFire

In Tanzu GemFire, a region is a fundamental data container that stores key/value pairs and supports distributed caching, querying, and data replication across cluster members. Regions can be configured for different use cases, including partitioned caching for scalability or replicated caching for redundancy.

## Create a Region with gfsh

A Tanzu GemFire region is the foundation of your caching architecture. It’s built for scalability, performance, and fault tolerance, but it’s essential to choose the right region type and redundancy based on your business requirements.

To create a region using the gfsh, use the following basic command:

```
gfsh> create region --name=exampleRegion --type=PARTITION
```

This command:

* Creates a region named exampleRegion.
* Uses the PARTITION type, where data is split across multiple servers for scalability.

### Commonly Used Region Types

| Region Type | Description |
| ----- | ----- |
| PARTITION | Data is distributed across servers; scales horizontally. |
| PARTITION\_REDUNDANT | Like PARTITION but with redundancy for high availability. |
| REPLICATE | Full copy of data on each server; good for small datasets. |
| REPLICATE\_PERSISTENT | Replicated with disk persistence for durability. |

### Key Options

| Option | Purpose |
| ----- | ----- |
| \--name | Name of the region. |
| \--type | Type of region: PARTITION, REPLICATE, etc. |
| \--redundant-copies | Number of extra copies for failover (for partitioned regions). |
| \--total-max-memory | Memory (MB) allocated across all members. |
| \--total-num-buckets | Number of data buckets (controls partition granularity). |
| \--disk-store | Disk store name for persistence or overflow. |
| \--eviction-max-memory | Threshold (MB) for memory eviction. |
| \--eviction-action | Action on eviction: overflow-to-disk or local-destroy. |
| \--cache-loader | Java class to load data when not in cache. |
| \--cache-writer | Java class to intercept write operations. |
| \--cache-listener | Java class to listen to region events. |
| \--gateway-sender-id | For WAN replication. |
| \--async-event-queue-id | For write-behind/async event processing. |
| \--off-heap | Store values off-heap for larger datasets. |

### Best Practices for Configuring Regions

When designing your GemFire regions:

* Use PARTITION\_REDUNDANT for production workloads needing high availability.
* Set memory limits and eviction policies to avoid resource exhaustion.
* Monitor region health and performance through built-in statistics.


### Create a Partitioned Region with Redundancy


```
gfsh> create region --name=CustomerData --type=PARTITION_REDUNDANT --redundant-copies=1  --total-max-memory=1024 --total-num-buckets=113
```

This creates a partitioned region with one redundant copy of each data bucket, ensuring that the system can tolerate node failures without data loss.

### Region Lifecycle Management Commands

List existing regions:

```
gfsh> list regions
```

Destroy a region:

```
gfsh> destroy region --name=myRegion
```

Deleting a region removes all its data and configuration from the cluster.

