# Running a Tanzu GemFire Server

This topic explains how to run a VMware Tanzu GemFire Server, the core component that hosts your application data, manages regions, and participates in distributed caching. It covers starting, configuring, monitoring, and stopping servers, as well as configuring WAN replication using gateway senders and receivers.

After starting the locator, the next step in building your Tanzu GemFire cluster is to bring up one or more servers. A Tanzu GemFire server is where your application data resides; it hosts regions, responds to client operations and participates in distributed caching.

## Start a Server with gfsh

To start a server using the Tanzu GemFire Shell (gfsh), use the following command:

```shell
gfsh> start server --name=server1 --locators=localhost[10334] --dir=server1
```

This does the following:

* Starts a server named server1
* Connects it to a locator at localhost on port 10334
* Stores server-specific files in the working directory server1

Optionally, you can include region definitions, JAR files, or custom JVM arguments using \--classpath and \--J options. Always point your server to a running locator to join the cluster correctly.

## Default Server Configuration and Log Files

Once started, the server creates a set of files in the specified directory. These files help monitor the server’s health and behavior, especially in debugging or performance tuning scenarios.

| File | Description |
| ----- | ----- |
| `server.log` | The main log file for all server events and diagnostics. |
| `statArchive.gfs` | Performance statistics and runtime metrics. |
| `server.pid` | Contains the process ID of the running server (useful for monitoring or termination). |
| `gemFire.properties` | Optional configuration overrides (if present). |

## Check Server Status

Check if a server is currently running by using:

```shell
gfsh> status server --dir=server1
```

This command returns the status of the server process, including whether it's running, its PID and its uptime. Use this command during automated deployments or to troubleshoot server crashes.

## Stop a Server

To stop a running server gracefully, use:

```shell
gfsh> stop server --name=server1
```

Or, if you prefer to reference the directory instead:

```shell
gfsh> stop server --dir=server1
```

Gracefully stopping the server ensures that all in-flight operations are completed and internal state is saved cleanly. Avoid killing the process manually unless absolutely necessary. Use stop server to avoid region corruption or loss of queued events in WAN or async setups.

A Tanzu GemFire server is where your application’s data lives. It’s designed for performance, scalability, and reliability but it’s important to manage it correctly.

Be sure to:

* Always connect servers to a running locator.
* Keep an eye on log and stats files for insight into server performance.
* Use status server and stop server for safe lifecycle management.
* Store each server in a dedicated working directory.

## Configuring Gateway Senders and Receivers for WAN Replication

When you're building multi-site deployments with Tanzu GemFire, enabling data replication across geographically distributed clusters is critical. That’s where gateway senders and gateway receivers come in. They form the backbone of WAN replication in Tanzu GemFire, allowing region events to flow from one site to another.

## Creating Gateway Sender

To create a gateway sender using gfsh, you must be connected to a JMX manager:

```shell
gfsh> create gateway-sender --id=sender1 --remote-distributed-system-id=2 --members=server1
```

This command:
* Creates a sender with ID sender1
* Points it to remote distributed system ID 2
* Installs the sender on member server1

>**Important**
>The configuration for a given \--id must be identical across all servers hosting that gateway sender.

**Key Gateway Sender Options**

| Parameter | Description |
| ----- | ----- |
| \--parallel | Enables parallel (region-wise) replication; default is serial. |
| \--batch-size | Max number of events per batch (default: 100). |
| \--batch-time-interval | Time in ms before sending partial batches (default: 1000 ms). |
| \--enable-persistence | If true, persist the queue to disk. |
| \--disk-store-name | Disk store to use for queue persistence/overflow. |
| \--dispatcher-threads | Number of threads to dispatch events (default: 5). |
| \--order-policy | Defines how ordering is preserved with multiple dispatcher threads. |
| \--gateway-event-filter | Optional custom filter class to skip events. |
| \--group-transaction-events | Ensures all events from a transaction are sent in the same batch. |

These settings allow you to fine-tune how the sender queues, processes and delivers data to the remote site.

**Example**:

```shell
gfsh> create gateway-sender --id=sender1 --remote-distributed-system-id=2 --members=server1 --parallel=true --batch-size=500 --dispatcher-threads=4
```

## Creating Gateway Receiver

A gateway receiver is the receiving end of WAN replication. It listens for incoming data from gateway senders at a remote site.
You can create a receiver using:

```shell
gfsh> create gateway-receiver --members=server2
```

This creates a receiver on server2, ready to accept events from a remote sender.

>**Note**
>You can have only one receiver per member, and the port is selected from a default or configured range.

### Key Gateway Receiver Options

| Parameter | Description |
| ----- | ----- |
| \--start-port / \--end-port | Port range the receiver listens on (default: 5000–5500). |
| \--bind-address | Network interface for binding incoming sender connections. |
| \--hostname-for-senders | Hostname/IP that the locator advertises to senders. |
| \--socket-buffer-size | Buffer size in bytes (should match sender config). |
| \--maximum-time-between-pings | Ping timeout (default: 60 seconds). |
| \--gateway-transport-filter | Optional custom transport filter class. |

 Example:

```shell
gfsh> create gateway-receiver --members=server2 --start-port=50510 --end-port=50520
```

## Stopping Gateway Senders and Receivers

To stop a sender:

```shell
gfsh> stop gateway-sender --id=sender1 --members=server1
```

To stop a receiver (by stopping the server it's on):

```shell
gfsh> stop server --name=server2
```

There’s no separate stop command for receivers since they are tightly coupled to the server lifecycle. Gateway senders and receivers are essential for enabling WAN replication between Tanzu GemFire clusters. They offer flexible configurations to optimize throughput, event batching, ordering, and persistence.

## Best Practices

* Always use identical configuration across all members hosting a given sender.
* Ensure sender and receiver buffer sizes match.
* Use batching and persistence features for better performance and reliability.
* Monitor queues using JMX beans to detect issues like queue growth or lag.