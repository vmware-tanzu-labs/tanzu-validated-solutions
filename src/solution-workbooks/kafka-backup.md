# Backing Up and Restoring the Apache Kafka Deployments on Tanzu Kubernetes Grid

[Apache Kafka](https://kafka.apache.org/) is a distributed streaming platform designed to build real-time pipelines, and is used as a message broker or as a replacement for a log aggregation solution for big data applications.

For this demonstration, we leveraged on Tanzu Kubernetes Grid 2.3.0 (Kubernetes 1.26.x) to create a well-configured and highly available infrastructure for the Apache Kafka deployment. The Tanzu Infrastructure played an important role in optimizing the deployment and management of Apache Kafka, adding further value to the backup and restore capabilities.

You can use a [Helm chart](https://github.com/bitnami/charts/tree/main/bitnami/kafka) to get started with an Apache Kafka cluster on Kubernetes.

Once the cluster is deployed and operational, it is important to back up its data regularly and ensure that it can easily be restored whenever needed. Data backup and restore procedures are also important in cases, such as, off-site data migration/data analysis, or application load testing.

This document explains the process to back up and restore a Apache Kafka Service on Tanzu Kubernetes Grid clusters using Velero, an open-source Kubernetes backup/restore tool.

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

## Deploy Apache Kafka Using Helm

For this demonstration purpose, we use Helm to deploy Apache Kafka using Helm on source cluster and upload some data to it. 

1. Create a new namespace `kafka` on source cluster for deploying the Apache Kafka Service.
1. Deploy Apache Kafka using Helm by running the following command:

    ```bash
    helm install kafka oci://registry-1.docker.io/bitnamicharts/kafka -n kafka
    ```
1. To upload messages into Apache Kafka, perform the following steps: 
 
    - Get Kafka user Password. </br>The default user is `user1`.

        ```bash
        kubectl get secret kafka-user-passwords --namespace kafka -o jsonpath='{.data.client-passwords}' | base64 -d | cut -d , -f 1
        ```
    - Create the `client.properties` file with following content:

        ```bash
        security.protocol=SASL_PLAINTEXT
        sasl.mechanism=SCRAM-SHA-256
        sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required \
            username="user1" \
            password="<Password>";
        ```
    - Create a pod that you can use as a Kafka client, and run the following commands to connect to the database:

        ```bash
        kubectl run kafka-client --restart='Never' --image docker.io/bitnami/kafka:3.6.1-debian-11-r0 --namespace kafka --command -- sleep infinity

        kubectl cp --namespace kafka ./client.properties kafka-client:/tmp/client.properties
        
        kubectl exec --tty -i kafka-client --namespace kafka -- bash
        
        chmod 777 /tmp/client.properties
        ```
    - Upload data by running the `kafka-console-producer.sh` script, and insert the data:

        ```bash
        kafka-console-producer.sh \
        --producer.config /tmp/client.properties \
        --broker-list kafka-controller-0.kafka-controller-headless.kafka.svc.cluster.local:9092,kafka-controller-1.kafka-controller-headless.kafka.svc.cluster.local:9092,kafka-controller-2.kafka-controller-headless.kafka.svc.cluster.local:9092 \
        --topic test

        >one
        >two
        >three
        >four
        ```
    - Verify the messages by running the `kafka-console-consumer.sh` script:
    
        ```bash
        kafka-console-consumer.sh \
        --consumer.config /tmp/client.properties \
        --bootstrap-server kafka.kafka.svc.cluster.local:9092 \
        --topic test \
        --from-beginning

        one
        two
        three
        four
        ```

## Back up the Apache Kafka Deployment on the Source Cluster

In this section, we'll use Velero to back up the Apache Kafka deployment including namespace.

1. Back up the database using velero:

    ```bash
    # velero backup create kafka-backup-01b --include-namespaces kafka
    Backup request "kafka-backup-01b" submitted successfully.
    Run `velero backup describe kafka-backup-01b` or `velero backup logs kafka-backup-01b` for more details.
    ```

1. Check the status of backup by using the following command:

    ```bash
    velero backup describe kafka-backup-01b --details
    ```

## Restore the Apache Kafka Deployment on the Destination Cluster

Now, we'll restore the Apache Kafka deployment on destination cluster.

1. Run the following command to restore the backup:

    ```bash
    # velero restore create --from-backup kafka-backup-01b
    Restore request "kafka-backup-01b-20231221113616" submitted successfully.
    Run `velero restore describe kafka-backup-01b-20231221113616` or `velero restore logs kafka-backup-01b-20231221113616` for more details.
    ```

1. Ensure that the PVCs are recovere,d and the status of the active PVC is bound:

    ```bash
    # kubectl get pvc -n kafka
    NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    data-kafka-controller-0   Bound    pvc-1627bd3a-f29e-4455-a1ab-46f0c78615b3   8Gi        RWO            default        2m44s
    data-kafka-controller-1   Bound    pvc-02315c12-388e-40ff-bd20-e0c6fa5a7283   8Gi        RWO            default        2m44s
    data-kafka-controller-2   Bound    pvc-b0ca13e9-3088-42c7-a2f0-89dd9504693b   8Gi        RWO            default        2m44s
    ```
1. Ensure that the pods are up and running:

    ```bash
    # kubectl get pods -n kafka
    NAME                     READY   STATUS    RESTARTS   AGE
    kafka-controller-0   1/1     Running   0          2m32s
    kafka-controller-1   1/1     Running   0          2m32s
    kafka-controller-2   1/1     Running   0          2m32s
    ```

1. Connect to Apache Kafka, and ensure that the messages are intact:

    - Create a pod that you can use as a Kafka client, and run the following commands to connect to the database:

        ```bash
        kubectl run kafka-client --restart='Never' --image docker.io/bitnami/kafka:3.6.1-debian-11-r0 --namespace kafka --command -- sleep infinity

        kubectl cp --namespace kafka ./client.properties kafka-client:/tmp/client.properties
        
        kubectl exec --tty -i kafka-client --namespace kafka -- bash
        
        chmod 777 /tmp/client.properties
        ```
    - Verify the messages by running the `kafka-console-consumer.sh` script:
    
        ```bash
        kafka-console-consumer.sh \
        --consumer.config /tmp/client.properties \
        --bootstrap-server kafka.kafka.svc.cluster.local:9092 \
        --topic test \
        --from-beginning

        one
        two
        three
        four
        ```


## Conclusion

Regular backups of your Apache Kafka deployments are crucial for ensuring data safety and minimizing downtime. By using the procedures explained in this document, you can establish a reliable backup routine and test restoration practices to guarantee a swift and successful recovery when needed.
