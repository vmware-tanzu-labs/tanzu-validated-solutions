
# Backing Up and Restoring the MariaDB Deployments on Tanzu Kubernetes Grid

MariaDB Galera Cluster makes it easy to create a high-availability database cluster with synchronous replication while retaining all the familiar MariaDB clients and tools.

For this demonstration, we leveraged on Tanzu Kubernetes Grid 2.3.0 (Kubernetes 1.26.x) to create a well-configured and highly available infrastructure for our MariaDB deployment. The Tanzu Infrastructure played an important role in optimizing the deployment, and managing MariaDB, adding further value to the backup and restore capabilities.

You can deploy a scalable MariaDB cluster on Tanzu Kubernetes Grid cluster using a [Helm chart](https://github.com/bitnami/charts/tree/main/bitnami/mariadb-galera). Once you have a MariaDB Galera Cluster deployed, you must put a data backup/restore strategy along with ongoing maintenance and disaster recovery. The data backup/restore strategy is required for many operational scenarios, such as, disaster recovery planning, off-site data analysis, or application load testing, and so on.

This document explains the process to back up and restore a MariaDB deployment on Tanzu Kubernetes Grid clusters using Velero, an open-source Kubernetes backup/restore tool.

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

## Deploy MariaDB Using Helm

For this demonstration purpose, we'll use Helm to deploy MariaDB using Helm on source cluster, and upload data to it.

1. Create a new namespace `maria-db1` on source cluster for deploying the MariaDB Galera cluster.
1. Deploy MariaDB Galera using Helm by running the following command:

    ```bash
    helm install galera oci://registry-1.docker.io/bitnamicharts/mariadb-galera \
    --namespace maria-db1 \
    --set rootUser.password=VMware1! \
    --set galera.mariabackup.password=VMware1!
    ```
1. Deploy Galera Client to connect to the database. </br>Then, create a new database and upload data:

    ```bash
    kubectl run galera-mariadb-galera-client --rm --tty -i --restart='Never' --namespace maria-db1 --image docker.io/bitnami/mariadb-galera:11.1.3-debian-11-r0 --command \
    -- mysql -h galera-mariadb-galera -P 3306 -uroot -p$(kubectl get secret --namespace maria-db1 galera-mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 -d) my_database

    
    CREATE DATABASE mydb;
    USE mydb;
    CREATE TABLE accounts (name VARCHAR(255) NOT NULL, total INT NOT NULL);
    INSERT INTO accounts VALUES ('user1', '1'), ('user2', '2'), ('user3', '3'), ('user4', '4'), ('user5', '5'), ('user6', '6'), ('user7', '7'), ('user8', '8'), ('user9', '9');
    exit
    ```
1. Validate the uploaded data by running the following command:

    ```bash
    > SELECT * FROM mydb.accounts;
    +-------+-------+
    | name  | total |
    +-------+-------+
    | user1 |     1 |
    | user2 |     2 |
    | user3 |     3 |
    | user4 |     4 |
    | user5 |     5 |
    | user6 |     6 |
    | user7 |     7 |
    | user8 |     8 |
    | user9 |     9 |
    +-------+-------+
    9 rows in set (0.001 sec)
    ```

## Back up the MariaDB Deployment on the Source Cluster

In this section, we'll use Velero to back up the MariaDB deployment including namespace. This approach requires scaling the cluster down to a single node to perform the backup. 

1. Scale down the cluster to single node:

    ```bash
    # kubectl scale statefulset --replicas=1 galera-mariadb-galera -n maria-db1
    statefulset.apps/galera-mariadb-galera scaled

    ## Obtain the name of the running pod. Make a note of the node number which is suffixed to the name. For example, if the running pod is galera-mariadb-galera-0, the node number is 0

    # kubectl get pods -n maria-db1
    NAME                      READY   STATUS    RESTARTS   AGE
    galera-mariadb-galera-0   1/1     Running   0          9m29s
    ```

1. Before backing up the data, aquire global read lock on all tables in the database. This lock prevents any further write (insert, update, delete) operations on the tables. However, it allows read operations to continue.

    ```bash
    kubectl run galera-mariadb-galera-client --rm --tty -i --restart='Never' --namespace maria-db1 --image docker.io/bitnami/mariadb-galera:11.1.3-debian-11-r0 --command \
    -- mysql -h galera-mariadb-galera -P 3306 -uroot -p$(kubectl get secret --namespace maria-db1 galera-mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 -d) my_database
    
    ##Command to aquire global read lock
    USE mydb;
    FLUSH TABLES WITH READ LOCK;
    ```

1. Now, create backup on source cluster using velero:

    ```bash
    # velero backup create galera-backup-05a --include-namespaces maria-db1
    Backup request "galera-backup-05a" submitted successfully.
    Run `velero backup describe galera-backup-05a` or `velero backup logs galera-backup-05a` for more details.
    ``` 

1. To ensure that the backup of all data including the active PVC is successful, run the following command:

    ```bash
    # velero backup describe galera-backup-05a
    Name:         galera-backup-05a
    Namespace:    velero
    Labels:       velero.io/storage-location=default
    Annotations:  velero.io/resource-timeout=10m0s
                velero.io/source-cluster-k8s-gitversion=v1.21.2+vmware.1-fips.1
                velero.io/source-cluster-k8s-major-version=1
                velero.io/source-cluster-k8s-minor-version=21

    Phase:  Completed


    Namespaces:
    Included:  maria-db1
    Excluded:  <none>

    Resources:
    Included:        *
    Excluded:        <none>
    Cluster-scoped:  auto

    Label selector:  <none>

    Or label selector:  <none>

    Storage Location:  default

    Velero-Native Snapshot PVs:  auto
    Snapshot Move Data:          false
    Data Mover:                  velero

    TTL:  720h0m0s

    CSISnapshotTimeout:    10m0s
    ItemOperationTimeout:  4h0m0s

    Hooks:  <none>

    Backup Format Version:  1.1.0

    Started:    2023-12-20 07:20:41 +0000 UTC
    Completed:  2023-12-20 07:21:46 +0000 UTC

    Expiration:  2024-01-19 07:20:41 +0000 UTC

    Total items to be backed up:  92
    Items backed up:              92

    Velero-Native Snapshots: <none included>

    kopia Backups (specify --details for more information):
    Completed:  2
    ```

1. After backing up the data, you might release the global read lock on all tables in the database. You must also scale the cluster back to its initial state:

    ```bash
    kubectl run galera-mariadb-galera-client --rm --tty -i --restart='Never' --namespace maria-db1 --image docker.io/bitnami/mariadb-galera:11.1.3-debian-11-r0 --command \
    -- mysql -h galera-mariadb-galera -P 3306 -uroot -p$(kubectl get secret --namespace maria-db1 galera-mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 -d) my_database
    
    ##Command to release global read lock
    USE mydb;
    UNLOCK TABLES;
    
    ##Scale up the cluster to only a initial state:
    kubectl scale statefulset --replicas=3 galera-mariadb-galera -n maria-db1
    ```

## Restore the MariaDB Deployment on the Destination Cluster

Now, we'll restore the MariaDB deployment on the destination cluster.

1. To restore the backup, run the following command:

    ```bash
    # velero restore create --from-backup galera-backup-05a
    Restore request "galera-backup-05a-20231220075647" submitted successfully.
    Run `velero restore describe galera-backup-05a-20231220075647` or `velero restore logs galera-backup-05a-20231220075647` for more details.
    ```
1. Ensure that the PVCs are recovered, and the status of the active PVC is bound:

    ```bash
    # kubectl get pvc -n maria-db1
    NAME                           STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    data-galera-mariadb-galera-0   Bound     pvc-a1fa9efa-ab11-40c5-b361-70aabbaebfc7   8Gi        RWO            default        114s
    data-galera-mariadb-galera-1   Pending                                                                        default        114s
    data-galera-mariadb-galera-2   Pending                                                                        default        114s
    ```
1. Ensure that the pod is up and running:

    ```bash
    # kubectl get pods -n maria-db1
    NAME                      READY   STATUS    RESTARTS   AGE
    galera-mariadb-galera-0   1/1     Running   0          88s
    ```
1. To connect to the database and to ensure that the data is intact, run the following command:

    ```bash
    kubectl run galera-mariadb-galera-client --rm --tty -i --restart='Never' --namespace maria-db1 --image docker.io/bitnami/mariadb-galera:11.1.3-debian-11-r0 --command \
    -- mysql -h galera-mariadb-galera -P 3306 -uroot -p$(kubectl get secret --namespace maria-db1 galera-mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 -d) my_database
    
    MariaDB [my_database]> SELECT * FROM mydb.accounts;
    +-------+-------+
    | name | total |
    +-------+-------+
    | user1 | 1 |
    | user2 | 2 |
    | user3 | 3 |
    | user4 | 4 |
    | user5 | 5 |
    | user6 | 6 |
    | user7 | 7 |
    | user8 | 8 |
    | user9 | 9 |
    +-------+-------+
    9 rows in set (0.001 sec)
    ```
1. Delete the unbound PVC, and scale up the cluster:

    ```bash
    ##Delete unbound PVC:
    $ kubectl delete pvc data-galera-mariadb-galera-1 data-galera-mariadb-galera-2 -n maria-db1
    persistentvolumeclaim "data-galera-mariadb-galera-1" deleted
    persistentvolumeclaim "data-galera-mariadb-galera-2" deleted
    
    ##Scale the Maria cluster back to its original size:
    # kubectl scale statefulset --replicas=3 galera-mariadb-galera -n maria-db1
    ```
1. Ensure that the PVCs are recreated, and required pods are up and running:

    ```bash
    # kubectl get pods -n maria-db1
    NAME READY STATUS RESTARTS AGE
    galera-mariadb-galera-0 1/1 Running 0 26m
    galera-mariadb-galera-1 1/1 Running 0 100s
    galera-mariadb-galera-2 1/1 Running 0 51s
    
    
    # kubectl get pvc -n maria-db1
    NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS AGE
    data-galera-mariadb-galera-0 Bound pvc-23162ccf-c61b-41c7-8f49-c08c342222fc 8Gi RWO default 27m
    data-galera-mariadb-galera-1 Bound pvc-fc18ac4d-f0b0-4da2-9ae2-f3759ed72cc1 8Gi RWO default 2m3s
    data-galera-mariadb-galera-2 Bound pvc-deec1841-9c83-4b9f-89cf-d8a02797d239 8Gi RWO default 74s
    ```
1. Connect to MariaDB and ensure the data integrity:

    ```bash
    kubectl run galera-mariadb-galera-client --rm --tty -i --restart='Never' --namespace maria-db1 --image docker.io/bitnami/mariadb-galera:11.1.3-debian-11-r0 --command \
    -- mysql -h galera-mariadb-galera -P 3306 -uroot -p$(kubectl get secret --namespace maria-db1 galera-mariadb-galera -o jsonpath="{.data.mariadb-root-password}" | base64 -d) my_database
    
    MariaDB [my_database]> SELECT * FROM mydb.accounts;
    +-------+-------+
    | name | total |
    +-------+-------+
    | user1 | 1 |
    | user2 | 2 |
    | user3 | 3 |
    | user4 | 4 |
    | user5 | 5 |
    | user6 | 6 |
    | user7 | 7 |
    | user8 | 8 |
    | user9 | 9 |
    +-------+-------+
    9 rows in set (0.001 sec)
    ``` 

## Conclusion

Regular backups of your MariaDB deployments are crucial for ensuring data safety and minimizing downtime. By using the procedures explained in this document, you can establish a reliable backup routine and test restoration practices to guarantee a swift and successful recovery when needed.