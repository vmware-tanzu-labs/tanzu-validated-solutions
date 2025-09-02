# Running a Tanzu GemFire Locator

This topic explains how to run a VMware Tanzu GemFire Locator, the cluster coordinator that enables member discovery, client load balancing, and WAN replication. It covers starting, configuring, monitoring, and stopping locators to ensure cluster availability and resilience.

To start a Tanzu GemFire cluster, the first component you bring up is the locator. It acts as the cluster coordinator, helping members find each other and join the system. Run a locator as a standalone process, typically using the Tanzu GemFire Shell (gfsh) and configure it to support both peer discovery and client load balancing.

Tanzu GemFire Locators can be lightweight, but they are mission-critical for keeping your cluster running, scalable, and highly available. From local server discovery to global WAN replication, the locator is the backbone of your system’s coordination.

## Start a locator using gfsh

```shell
gfsh> start locator --name=locator1 --port=10334 --dir=locator1
```

This command:

* Starts the locator with the name `locator1`
* Listens on port 10334 (default)
* Uses the specified working directory `locator1`

The locator creates a `locator.dat` file in its directory, which stores membership and configuration data. This file is important for rejoining or recovering the cluster if the locator is restarted.

>**Note**

>* Only one locator can run per process instance.
>* The locator must be started before any servers to allow them to discover and join the system.

## Locator Configuration and Log Files

When you start a locator using gfsh, specify a working directory using the `--dir` option. This directory holds critical files:

| File | Description |
| ----- | ----- |
| `locator.log` | Main log file for the locator process. All startup info, warnings, and errors are logged here. |
| `locator.dat` | Stores cluster membership information and state. Used for reconnection after restarts. |
| `statArchive.gfs` | Contains performance statistics, useful for monitoring and analysis. |

Always retain `locator.dat` if you plan to restart a locator in the same cluster. Deleting it can cause cluster inconsistency.

## Restarting Locators

If you restart a locator, make sure the same working directory is used to maintain the cluster state via the persisted `locator.dat` file. In production, always run multiple locators for redundancy. This provides redundancy, so if one goes down, others can still coordinate discovery.

## Check Locator Status

Check the status of a locator using the status locator command:

```shell
gfsh> status locator --dir=locator1
```

This command shows whether the locator is running, along with its process ID and other metadata.

It's helpful for:

* Verifying startup
* Diagnosing issues after crashes
* Integrating with automation and monitoring tools

## Stopping the Locator

To shut down a locator gracefully, use the `stop locator` command:

```shell
gfsh> stop locator --name=locator1
```

If needed, you can also stop it by pointing to its directory:

```shell
gfsh> stop locator --dir=locator1
```

Avoid killing the locator process directly, as this can prevent cleanup of internal metadata and files like `locator.dat`.

## Locators in Multi-Site (WAN) Deployments

In WAN (multi-site) setups, locators play a critical role in cross-cluster discovery. Each cluster must be aware of remote site locators to establish gateway communication.

To enable this, configure remote-locators:

```shell
gfsh> start locator --name=locator1 --dir=locator1 --J=-DGemFire.remote-locators=remote-site-host[10334]
```

This allows:

* Gateway senders in one site to find receivers in another site
* Automatic failover and recovery of gateway connections
* Scalability across geographically distributed clusters

## Best Practices

Run at least two locators per site, and ensure proper network connectivity between remote locators for resilience.

Be sure to:

* Maintain clean log directories.
* Monitor locator status regularly.
* Stop and restart them gracefully.
* Configure remote locators in WAN setups.