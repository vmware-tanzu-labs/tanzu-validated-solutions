# Backing Up and Restoring the Rabbitmq Deployments on Tanzu Kubernetes Grid

[RabbitMQ](https://www.rabbitmq.com/) is a highly-scalable and reliable open-source message broking system. It supports a number of different messaging protocols, message qeueing, and plug-ins for additional customization.

For this demonstration, we leveraged on Tanzu Kubernetes Grid 2.3.0 (Kubernetes 1.26.x) to create a well-configured and highly available infrastructure for the Rabbitmq deployment. The Tanzu Infrastructure played an important role in optimizing the deployment and management of Rabbitmq, adding further value to the backup and restore capabilities.

You can deploy a scalable RabbitMQ cluster on Tanzu Kubernetes Grid cluster using a [Helm chart](https://github.com/bitnami/charts/tree/main/bitnami/rabbitmq). Once the RabbitMQ cluster is operational, backing up the data held within it becomes an important and ongoing administrative task. A data backup/restore strategy is required not only for data security and disaster recovery planning, but also for other tasks, such as, off-site data analysis or application load testing.


This guide explains the process to back up and restore a RabbitMQ deployment on Tanzu Kubernetes Grid clusters using Velero, an open-source Kubernetes backup/restore tool.

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

## Deploy Rabbitmq Using Helm

For this demonstration purpose, we use Helm to deploy Rabbitmq using Helm on source cluster, and upload some data to it:

1. Deploy Rabbitmq by running the below command:

    ```bash
    # helm install rabbitmq oci://registry-1.docker.io/bitnamicharts/rabbitmq \
    --namespace rabbitmq \
    --set auth.password=VMware1! \
    --set service.type=LoadBalancer \
    --set plugins=rabbitmq_management \
    --set replicaCount=3
    ```
1. Validate the the Rabbitmq deployment is successful:

    ```bash
    # kubectl get all -n rabbitmq
    NAME             READY   STATUS    RESTARTS   AGE
    pod/rabbitmq-0   1/1     Running   0          1d
    pod/rabbitmq-1   1/1     Running   0          1d
    pod/rabbitmq-2   1/1     Running   0          1d

    NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                         AGE
    service/rabbitmq            LoadBalancer   100.69.160.209   172.16.48.139   5672:32580/TCP,4369:31225/TCP,25672:31930/TCP,15672:31567/TCP   1d
    service/rabbitmq-headless   ClusterIP      None             <none>          4369/TCP,5672/TCP,25672/TCP,15672/TCP                           1d

    NAME                        READY   AGE
    statefulset.apps/rabbitmq   3/3     1d
    ```
1. Download and install `Rabbitmqadmin` CLI on your local machine:

    ```bash
    # export SERVICE_IP=$(kubectl get svc --namespace rabbitmq rabbitmq --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

    # wget http://$SERVICE_IP:15672/cli/rabbitmqadmin
    --2023-12-21 10:25:14--  http://172.16.48.139:15672/cli/rabbitmqadmin
    Connecting to 172.16.48.139:15672... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 42533 (42K) [application/octet-stream]
    Saving to: ‘rabbitmqadmin.2’

    rabbitmqadmin.2      100%[======================>]  41.54K  --.-KB/s    in 0.001s

    2023-12-21 10:25:14 (69.0 MB/s) - ‘rabbitmqadmin.2’ saved [42533/42533]

    # chmod +x rabbitmqadmin
    # cp ./rabbitmqadmin /usr/local/bin
    ```
1. Upload data by creating Queues and messages:

    ```bash
    # rabbitmqadmin -H $SERVICE_IP -u user -p $Password declare queue name=my-queue durable=true
    queue declared

    # rabbitmqadmin -H $SERVICE_IP -u user -p $Password publish routing_key=my-queue payload="message 1"  properties="{\"delivery_mode\":2}"
    Message published

    # rabbitmqadmin -H $SERVICE_IP -u user -p $Password publish routing_key=my-queue payload="message 2"  properties="{\"delivery_mode\":2}"
    Message published

    # rabbitmqadmin -H $SERVICE_IP -u user -p $Password publish routing_key=my-queue payload="message 3"  properties="{\"delivery_mode\":2}"
    Message published
    ```
1. Validate the queue and messages by accessing the management console over the loadbalancer IP&Port.

## Back Up the RabbitMQ Deployment on the Source Cluster

In this section, we'll use Velero to back up the Rabbimq deployment including namespace.

> **Note** Before backing up the data, pause the producers and consumers of messages during the backup to ensure a consistent state. This can be achieved by stopping or pausing applications that produce or consume messages.

1. Create a backup of the Rabbitmq namespace in the source cluster:

    ```bash
    # velero backup create rabbitmq-backup-01a --include-namespaces rabbitmq
    Backup request "rabbitmq-backup-01a" submitted successfully.
    Run `velero backup describe rabbitmq-backup-01a` or `velero backup logs rabbitmq-backup-01a` for more details.
    ```
1. To view the content of the backup, and confirm that it contains all the required resources, run the following command below:

    ```bash
    # velero backup describe rabbitmq-backup-01a --details
    
      v1/Namespace:
        - rabbitmq
      v1/PersistentVolume:
        - pvc-329333ce-caed-4a9a-9163-4d13f3606ea2
        - pvc-a3bd6434-a584-41b8-974f-17c5631252bf
        - pvc-dd062669-b45b-41b6-8b0d-a42273744bad
      v1/PersistentVolumeClaim:
        - rabbitmq/data-rabbitmq-0
        - rabbitmq/data-rabbitmq-1
        - rabbitmq/data-rabbitmq-2
      v1/Pod:
        - rabbitmq/rabbitmq-0
        - rabbitmq/rabbitmq-1
        - rabbitmq/rabbitmq-2
      v1/Secret:
        - rabbitmq/rabbitmq
        - rabbitmq/rabbitmq-config
        - rabbitmq/sh.helm.release.v1.rabbitmq.v1
      v1/Service:
        - rabbitmq/rabbitmq
        - rabbitmq/rabbitmq-headless
      v1/ServiceAccount:
        - rabbitmq/default
        - rabbitmq/rabbitmq
    
    Velero-Native Snapshots: <none included>
    
    kopia Backups:
      Completed:
        rabbitmq/rabbitmq-0: data
        rabbitmq/rabbitmq-1: data
        rabbitmq/rabbitmq-2: data
    ```

## Restore the RabbitMQ Deployment on the Destination Cluster

We'll now restore the Rabbitmq backup on the destination cluster.

1. To restore the Rabbimq deployment, run the following command:

    ```bash
    # velero restore create --from-backup rabbitmq-backup-01a
    Restore request "rabbitmq-backup-01a-20231221110344" submitted successfully.
    Run `velero restore describe rabbitmq-backup-01a-20231221110344` or `velero restore logs rabbitmq-backup-01a-20231221110344` for more details.
    ```
1. Validate that the Rabbitmq deployment restore is successful:

    ```bash
    # kubectl get all -n rabbitmq
    NAME             READY   STATUS    RESTARTS   AGE
    pod/rabbitmq-0   1/1     Running   0          79s
    pod/rabbitmq-1   1/1     Running   0          79s
    pod/rabbitmq-2   1/1     Running   0          79s

    NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                         AGE
    service/rabbitmq            LoadBalancer   100.70.78.228   172.16.48.140   5672:31947/TCP,4369:32370/TCP,25672:32684/TCP,15672:31691/TCP   78s
    service/rabbitmq-headless   ClusterIP      None            <none>          4369/TCP,5672/TCP,25672/TCP,15672/TCP                           78s

    NAME                        READY   AGE
    statefulset.apps/rabbitmq   3/3     20s
    root@photon [ ~/velero ]# kubectl get pvc -n rabbitmq
    NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    data-rabbitmq-0   Bound    pvc-4a029420-2ecd-48b6-acaa-9d549dd0b3f6   8Gi        RWO            default        88s
    data-rabbitmq-1   Bound    pvc-5aa78194-1422-43fe-ad72-853c797f44ff   8Gi        RWO            default        88s
    data-rabbitmq-2   Bound    pvc-ecb59129-675e-4797-b7c7-d73152fcff5e   8Gi        RWO            default        88s
    ```
1. Confirm the data integrity by validating the queue and messages by accessing the management console over the loadbalancer IP&Port.

## Conclusion

Regular backups of your RabbitMQ deployments are crucial for ensuring data safety and minimizing downtime. By using the procedures explained in this document, you can establish a reliable backup routine and test restoration practices to guarantee a swift and successful recovery when needed.