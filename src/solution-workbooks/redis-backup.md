# Backing Up and Restoring the Redis Deployments on Tanzu Kubernetes Grid

Redis is a popular open-source in-memory datastore with a set of advanced features for high availability and data optimization.

For this demonstration, we leveraged Tanzu Kubernetes Grid 2.3.0 (Kubernetes 1.26.x) to create a well-configured and highly available infrastructure for our Redis deployment. The Tanzu Infrastructure played an important role in optimizing the deployment and management of Redis, adding further value to the backup and restore capabilities.

You can use a [Helm chart](https://github.com/bitnami/charts/tree/main/bitnami/redis-cluster) to deploy a Redis cluster with sharding, and multiple write points on Kubernetes.

Once you deploy the Redis cluster on Kubernetes, it is essential to have a data backup strategy to protect the data within it. This backup strategy is required for many operational scenarios, such as, disaster recovery planning, off-site data analysis, or application load testing and so on.

This document explains the process to back up and restore a Redis Service on Tanzu Kubernetes Grid clusters using Velero, an open-source Kubernetes backup/restore tool.

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

## Deploy Redis Using Helm

For this demonstration purpose, we use Helm to install Redis on the source cluster and upload some data to it. 

1. Create a new namespace `redis` on source cluster for deploying the Redis Service.
1. Deploy Redis using Helm by running the following command:

    ```bash
    helm install redis oci://registry-1.docker.io/bitnamicharts/redis-cluster \
    --namespace redis \
    --set rootUser.password=VMware1!
    ```
1. Export the `REDIS_PASSWORD` which is used to connect to the database:

    ```bash
    export REDIS_PASSWORD=$(kubectl get secret --namespace "redis" redis-redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d)
    ```
1. Deploy a Redis client pod that you can use as a client to connect to the database:

    ```bash
    kubectl run --namespace redis redis-redis-cluster-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
    --image docker.io/bitnami/redis-cluster:7.2.3-debian-11-r1 -- bash
    ```
1. Connect to the database by using the Redis CLI:

    ```bash
    redis-cli -c -h redis-redis-cluster -a $REDIS_PASSWORD
    ```
1. Upload data for testing purpose:

    ```bash
    set foo 100
    set bar 200
    set foo1 300
    set bar1 400
    ```
1. Validate the uploaded data:

    ```bash
    get foo
    get bar 
    get foo1 
    get bar1 
    ```

## Back up the Redis Deployment on the Source Cluster

In this section, we'll use Velero to back up the Redis deployment including namespace.

1. Before backing up the data, use `BGSAVE` command for creating backups in Redis. `BGSAVE` creates a snapshot of the in-memory dataset and writes it to the disk. <br>

    > **Note** If you have specific requirements for data consistency or if you want to create a point-in-time snapshot, you can use the `BGSAVE` command in Redis to trigger a background save operation before initiating the Velero backup. However, in many cases, the combination of Velero Filesystem backup is sufficient for routine backups without the need to stop the Redis database.
 
    ```bash
    kubectl run --namespace redis redis-redis-cluster-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
    --image docker.io/bitnami/redis-cluster:7.2.3-debian-11-r1 -- bash

    redis-cli -c -h redis-redis-cluster -a $REDIS_PASSWORD

    BGSAVE
    
    exit
    ```
1. Back up the Redis database by using velero:

    ```bash
    # velero backup create redis-backup-05a --include-namespaces redis
    Backup request "redis-backup-05a" submitted successfully.
    Run `velero backup describe redis-backup-05a` or `velero backup logs redis-backup-05a` for more details.
    ```
1. Validate the backup status by running the following command:

    ```bash
    # velero backup describe redis-backup-05a --details
    ```

## Restore the Redis Deployment on the Destination Cluster

We'll now restore the Redis deployment on the destination cluster.

1. Run the following command to restore the backup:

    ```bash
    # velero restore create --from-backup redis-backup-05a 
    Restore request "redis-backup-05a-20231220093241" submitted successfully.
    Run `velero restore describe redis-backup-05a-20231220093241` or `velero restore logs redis-backup-05a-20231220093241` for more details.
    ```
1. Connect to the databse, and ensure that the data is intact:

    ```bash
    kubectl run --namespace redis redis-redis-cluster-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
    --image docker.io/bitnami/redis-cluster:7.2.3-debian-11-r1 -- bash

    redis-cli -c -h redis-redis-cluster -a $REDIS_PASSWORD
    
    ##  validate the data
    get foo 
    get bar
    get foo1 
    get bar1 
    ```

## Conclusion

Regular backups of your Redis deployments are crucial for ensuring data safety and minimizing downtime. By using the procedures explained in this document, you can establish a reliable backup routine and test restoration practices to guarantee a swift and successful recovery when needed.