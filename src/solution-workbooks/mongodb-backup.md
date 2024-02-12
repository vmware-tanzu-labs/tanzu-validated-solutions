# Backing Up and Restoring the MongoDB Deployments on Tanzu Kubernetes Grid

MongoDB(R) is a relational open source NoSQL database. It is easy to use, and stores data in JSON-like documents. It also supports automated scalability and high-performance. MomgoDB(R) is ideal for developing cloud native applications.

For this demonstration, we leveraged Tanzu Kubernetes Grid 2.3.0 (Kubernetes 1.26.x) to create a well-configured and highly available infrastructure for the MongoDB deployment. The Tanzu Infrastructure played an important role in optimizing the deployment and management of MongoDB, adding further value to the backup and restore capabilities.

You can use a [Helm chart](https://github.com/bitnami/charts/tree/main/bitnami/mongodb) to deploy a horizontally-scalable MongoDB cluster on Kubernetes with separate primary, secondary, and arbiter nodes. 

However, setting up a scalable MongoDB service is just the beginning; you also need to regularly backup the data being stored in the service, and to have the ability to restore it elsewhere if needed. Few Common scenarios for such backup/restore operations include disaster recovery, off-site data analysis, application load testing, and so on.

This document explains the process to back up and restore a MongoDB Service on Tanzu Kubernetes Grid clusters using Velero, an open-source Kubernetes backup/restore tool.

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

## Deploy MongoDB Using Helm

For this demonstration purpose, we use Helm to deploy MongoDB on source cluster and add some data to it. 

1. Create a new namespace `mongodb` on source cluster for deploying the MongoDB Service.

1. Deploy MongoDB using Helm by running the following command:

    ```bash
    helm install mongodb oci://registry-1.docker.io/bitnamicharts/mongodb \
    --namespace mongodb \
    --set replicaSet.enabled=true \
    --set mongodbRootPassword=VMware1!
    ```
1. Deploy the MongoDB Client to connect to the database. </br>Then create a new database and load some data:

    ```bash
    ##Get Password
    export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace mongodb mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
    
    ##Deploy MongoDB Client
    kubectl run --namespace mongodb mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:7.0.4-debian-11-r2 --command -- bash
    
    ##Login to MongoDB
    mongosh admin --host "mongodb" --authenticationDatabase admin -u root -p <Password Obtained Above>
    
    ##Create Database using the "use" command
    
    use mydb
    db.accounts.insert({name:"john", total: "1058"})
    db.accounts.insert({name:"jane", total: "6283"})
    db.accounts.insert({name:"james", total: "472"})
    ```
1. Validate the data on the database by running the following command:

    ```bash
    mydb> db.accounts.find()
    [
    {
        _id: ObjectId('6582bae1256edf3a142275d0'),
        name: 'john',
        total: '1058'
    },
    {
        _id: ObjectId('6582bae1256edf3a142275d1'),
        name: 'jane',
        total: '6283'
    },
    {
        _id: ObjectId('6582bae4256edf3a142275d2'),
        name: 'james',
        total: '472'
    }
    ]
    ```

## Back Up the MongoDB deployment on the Source Cluster

In this section, we'll use Velero to back up the MongoDB deployment including namespace.

1. It's recommended to lock the database before taking the backup. This lock prevents any further write (insert, update, delete) operations on the tables, but it allows read operations to continue.

    - Deploy the MongoDB Client:

        ```bash
        kubectl run --namespace mongodb mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:7.0.4-debian-11-r2 --command -- bash
        ```
    - log in to MongoDB using the password obtained in the previous step:

        ```bash
        mongosh admin --host "mongodb" --authenticationDatabase admin -u root -p <Password Obtained Above>
        ```
    - Switch to MongoDB:

        ```bash
        use mydb
        ```
    - Lock the database:

        ```bash
        ##Locking a database with fsyncLock is usually done for backup or maintenance purposes and should be done cautiously, especially in a production environment. App team must understand all implications before performing this operation
        ## "fsyncLock" command flushes all pending writes to disk and lock the database
        
        ##Lock the Database using below for admin DB
        db.runCommand({ fsync: 1, lock: true })
        
        ##Lock the Database using below for non-admin DB
        db.fsyncLock()
        
        
        ## To check if a database is currently locked using fsync in MongoDB:
        db.currentOp()
        
        ##Snippet of O/P, which confirms that the DB is locked
            lockStats: {
                ParallelBatchWriterMode: { acquireCount: { r: Long('1') } },
                FeatureCompatibilityVersion: { acquireCount: { w: Long('1') } },
                ReplicationStateTransition: { acquireCount: { w: Long('1') } },
                Global: {
                acquireCount: { w: Long('1') },
                acquireWaitCount: { w: Long('1') },
                timeAcquiringMicros: { w: Long('17050151') }
                }
            },
            waitingForFlowControl: false,
            flowControlStats: { acquireCount: Long('1') }
        ```
1. Back up the database using velero:

    ```bash
    # velero backup create mongo-backup-01b --include-namespaces mongodb
    Backup request "mongo-backup-01b" submitted successfully.
    Run `velero backup describe mongo-backup-01b` or `velero backup logs mongo-backup-01b` for more details.
    ```
1. Validate the backup by running the following command:

    ```bash
    # velero backup describe mongo-backup-01b --details
    ```
1. Release the lock on database if required:

    ```bash
    ##Deploy MongoDB Client
    kubectl run --namespace mongodb mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:7.0.4-debian-11-r2 --command -- bash
    
    ##Login to MongoDB
    mongosh admin --host "mongodb" --authenticationDatabase admin -u root -p <Password Obtained Above>
    
    ##Switch to DB
    use mydb
    
    ##Unlock Commands
    ##For Admin DB
    db.$cmd.sys.unlock.findOne()
        
    ##For Non-Admin DB
    db.fsyncUnlock()   
    ```

## Restore the MongoDB Deployment on the Destination Cluster

We'll now restore the MongoDB deployment on the destination cluster.

1. To restore the backup, run the following command:

    ```bash
    # velero restore create --from-backup mongo-backup-01b
    Restore request "mongo-backup-01b-20231220101027" submitted successfully.
    Run `velero restore describe mongo-backup-01b-20231220101027` or `velero restore logs mongo-backup-01b-20231220101027` for more details.
    ```
1. Ensure that the PVCs are recovered, and the status of the active PVC is bound:

    ```bash
    # kubectl get pvc -n mongodb
    NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    mongodb   Bound    pvc-05605ca6-a248-484e-9fe4-09ceb4c36f92   8Gi        RWO            default        103s
    ```
1. Ensure that the pod is up and running:

    ```bash
    # kubectl get pods -n mongodb
    NAME                       READY   STATUS    RESTARTS   AGE
    mongodb-7d5fccddbf-txvk5   1/1     Running   0          2m11s
    ```
1. Connect to MongoDB and ensure that the data is intact:

    ```bash
    ##Get Password
    export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace mongodb mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
    
    ##Deploy MongoDB Client
    kubectl run --namespace mongodb mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:7.0.4-debian-11-r2 --command -- bash
    
    ##Login to MongoDB
    mongosh admin --host "mongodb" --authenticationDatabase admin -u root -p <Password Obtained Above>
    
    ##Switch to intended DB
    use mydb
    
    ##Validata the data
    db.accounts.find()
    ```


## Conclusion

Regular backups of your MongoDB deployments are crucial for ensuring data safety and minimizing downtime. By using the procedures explained in this document, you can establish a reliable backup routine and test restoration practices to guarantee a swift and successful recovery when needed.