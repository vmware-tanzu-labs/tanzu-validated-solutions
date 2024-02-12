# Backing Up and Restoring the KeyDB deployments on Tanzu Kubernetes Grid

KeyDB is a open source in-memory data store with a number of advanced features for high availability and data optimization. Its a high performance fork of Redis with a focus on multi-threading, memory efficiency, and high throughput. KeyDB maintains full compatibility with the Redis protocol, modules, and scripts. All 16 default logical databases on each KeyDB instance can be used and standard KeyDB/Redis protocol is supported without any other limitations.

For this demonstration, we leveraged on Tanzu Kubernetes Grid 2.3.0 (Kubernetes 1.26.x) to create a well-configured and highly available infrastructure for our KeyDB deployment. The Tanzu Infrastructure played an important role in optimizing the deployment and management of KeyDB, adding further value to the backup and restore capabilities. 

Once you have your KeyDB cluster deployed on Kubernetes, it is essential to put a data backup strategy in place to protect the data within KeyDB. This backup strategy is needed for many operational scenarios, including disaster recovery planning, off-site data analysis, application load testing, and so on.

This document explains the process to back up and restore a KeyDB Service on Tanzu Kubernetes Grid clusters using Velero, an open-source Kubernetes backup/restore tool.

## Prerequisites
- Configure two separate TKG Workload: 
  - A source cluster 
  - A destination cluster 
- Install the `kubectl` and `Helm v3` CLI on the client machine.
- Install the Velero CLI on the client machine.
- Configure a S3 compatible storage for storing the backups.
- Install Velero on the source and destination cluster. 
- For more information about Velero installation and best practices, see [Installing Velero in Tanzu Kubernetes Cluster
](./velero-with-restic.md).

## Deploy KeyDB Uusing Helm

For this demonstration purpose, we use Helm deploy KeyDB using Helm on source cluster, and upload data to it. 

1. Create a new namespace `keydb` on source cluster for deploying the KeyDB Service.

1. Deploy KeyDB using Helm by running the following command:

    ```bash
    helm repo add enapter https://enapter.github.io/charts/
    helm install keydb enapter/keydb -n keydb

    ```

1. Deploy a Redis client pod that you can use as a client to connect to KeyDB database:

    ```bash
    kubectl run --namespace keydb keydb-cluster-client --rm --tty -i --restart='Never' --image docker.io/bitnami/redis-cluster:7.2.3-debian-11-r1 -- bash
    ```
1. Connect to KeyDB using the RedisCLI:

    ```bash
    redis-cli -c -h keydb
    ```
1. Upload data for testing purposes:

    ```bash
    set foo 100
    set bar 200
    set foo1 300
    set bar1 400
    ```
1. Validate that the data has been uploaded:

    ```bash
    get foo
    get bar
    get foo1 
    get bar1 
    ```

## Back up the KeyDB Deployment on the Source Cluster

In this section, we'll use Velero to back up the KeyDB deployment including namespace.

1. Before taking the backup, run the `BGSAVE` command for creating backups in KeyDB. The `BGSAVE` command creates a snapshot of the in-memory dataset and writes it to the disk. <br>

    > **Note** If you have specific requirements for data consistency or if you want to create a point-in-time snapshot, you can consider using the `BGSAVE` command in KeyDB to trigger a background save operation before initiating the Velero backup. However, in many cases, the combination of Velero and Restic is sufficient for routine backups without the need to stop the KeyDB database.
 
    ```bash
    kubectl run --namespace keydb keydb-cluster-client --rm --tty -i --restart='Never' --image docker.io/bitnami/redis-cluster:7.2.3-debian-11-r1 -- bash

    redis-cli -c -h keydb

    BGSAVE
    
    exit
    ```
1. Backup the KeyDB database using velero:

    ```bash
    # velero backup create keydb-backup-01a --include-namespaces keydb
    Backup request "keydb-backup-01a" submitted successfully.
    Run `velero backup describe keydb-backup-01a` or `velero backup logs keydb-backup-01a` for more details.
    ```
1. Validate the backup status by running the following command:

    ```bash
    # velero backup describe keydb-backup-01a --details
    ```

## Restore the KeyDB Deployment on the Destination Cluster

We'll now restore the KeyDB deployment on the destination cluster.

1. To restore the backup, run the following command:

    ```bash
    # velero restore create --from-backup keydb-backup-01a
    Restore request "keydb-backup-01a-20231221082628" submitted successfully.
    Run `velero restore describe keydb-backup-01a-20231221082628` or `velero restore logs keydb-backup-01a-20231221082628` for more details.

    ```
1. Ensure that the PVCs are recovered, and the status of the active PVC is bound:

    ```bash
    # kubectl get pvc -n keydb
    NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    keydb-data-keydb-0   Bound    pvc-ccffc288-9e83-4214-8c17-ee291db5d819   1Gi        RWO            default        89s
    keydb-data-keydb-1   Bound    pvc-d3618a90-d650-4346-ae40-8d54b800e03a   1Gi        RWO            default        89s
    keydb-data-keydb-2   Bound    pvc-da9107af-f184-4f4c-9e85-744b9634b9ef   1Gi        RWO            default        89s
    ```
1. Ensure that the pods are up and running:

    ```bash
    # kubectl get pods -n keydb
    NAME          READY   STATUS    RESTARTS   AGE
    keydb-0   1/1     Running   0          79s
    keydb-1   1/1     Running   0          79s
    keydb-2   1/1     Running   0          79s
    ```
1. Connect to the databse and ensure that data is intact:

    ```bash
    # kubectl run --namespace keydb keydb-cluster-client --rm --tty -i --restart='Never' --image docker.io/bitnami/redis-cluster:7.2.3-debian-11-r1 -- bash
    If you don't see a command prompt, try pressing enter.

    I have no name!@keydb-cluster-client:/$ redis-cli -c -h keydb

    keydb:6379> get foo
    "100"
    keydb:6379> get boo
    "200"
    keydb:6379> get foo1
    "300"
    keydb:6379> get boo1
    "400"
    ```

## Conclusion

Regular backups of your MariaDB deployments are crucial for ensuring data safety and minimizing downtime. By using the procedures explained in this document, you can establish a reliable backup routine and test restoration practices to guarantee a swift and successful recovery when needed.