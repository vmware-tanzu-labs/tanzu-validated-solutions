# Locators and Servers

This topic explains the roles and functions of VMware Tanzu GemFire Locators and Servers, highlighting how they work together to ensure cluster coordination, data availability, and efficient client request handling.

- **Tanzu GemFire Locator**: A lightweight process that plays a central role in system coordination.
- **Tanzu GemFire Server**:  A process that hosts data regions, handles read and write operations, and serves requests from both clients and peer members in the cluster.

## Locators

A Tanzu GemFire Locator helps new members (servers, locators, or clients) discover existing members of the cluster and provides load balancing for client connections to servers.

It is responsible for two key functions:

* Cluster Member Discovery: Enables new servers to discover and join the existing distributed system by providing information about active cluster members.
* Client Connection Routing: Guides clients to connect with the most suitable (often least-loaded) cache server, enabling load balancing and high availability.

Tanzu GemFire locators can operate in different modes depending on your setup:

* Peer Locator
  * Supports member discovery.
  * Enables new servers or locators to find and connect to the existing cluster.
  * Maintains a membership list and shared view of the distributed system.
* Server Locator
  * Supports client connection discovery and load balancing.
  * Helps clients locate the least-loaded servers.
  * Enables high availability for client-to-server connections.

### Recommendations for Installing Locators

* Always install at least two locators in each cluster to keep the system available, even if one locator goes down.
* In production, run locators on separate VMs or containers instead of placing them on the same machines as data-heavy servers.
* For WAN environments, make sure the network connection between locators in different sites is stable and low-latency to ensure smooth communication.

By acting as the discovery, coordination, and client routing layer, the Tanzu GemFire Locator forms the backbone of your cluster’s connectivity. A well-configured locator setup ensures your distributed system remains connected, balanced, and resilient, even as it scales across regions and data centers.

## Server

A Tanzu GemFire Server:

* Hosts data regions, the in-memory equivalent of tables or datasets.
* Accepts client connections, processes queries, and returns results.
* Participates in distributed caching, function execution, event propagation, and WAN replication.
* Works with locators to ensure high availability and scalability.