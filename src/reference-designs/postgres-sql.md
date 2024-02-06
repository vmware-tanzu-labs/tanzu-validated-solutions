# High Availability Failover in PostgreSQL backed by VMware Tanzu

High Availability (HA) failover in PostgreSQL supported by Tanzu-powered backend infrastructure plays a pivotal role in the domain of database management. This ensures uninterrupted accessibility and data integrity, offering protection against hardware failures, network issues, and unforeseen circumstances. The resilience of PostgreSQL is realized through a harmony of resilient replication mechanisms, and tools seamlessly orchestrating automatic transitions between primary and standby nodes within the Tanzu environment.

## Components
The following components have been utilized for the deployment of PostgreSQL High Availability (HA) failover system:

### Tanzu Infrastructure Integration
We leveraged Tanzu Kubernetes Grid (informally known as TKGm) 2.3.0 to create a well-configured and highly available infrastructure for our PostgreSQL deployment. The Tanzu Infrastructure played an important role in optimizing the deployment and management of PostgreSQL, adding further value to the failover capabilities.


### Centralized Management with Tanzu
Tanzu's centralized management capabilities simplify the administration of PostgreSQL deployments. The Tanzu portfolio provides a unified control plane for deploying, scaling, and managing applications including PostgreSQL instances. This centralized approach streamlines operations reducing the complexity associated with managing distributed databases.

### Replication and Failover Mechanism
PostgreSQL's HA strategy lies in a robust replication mechanism. This mechanism maintains a standby node that mirrors the data of the primary node. The replication process can be synchronous or asynchronous, offering flexibility based on performance and reliability requirements. This synchronized standby node facilitates a smooth transition in case of a primary node failure, ensuring data consistency and availability.


### Replication Manager
As an open-source tool, the Replication Manager (informally known as repmgr) simplifies the administration of PostgreSQL replication and failover. By constantly monitoring the health of the primary node, repmgr triggers the promotion of a standby node to the new primary node upon detecting a failure. This automated process minimizes downtime and preserves the data consistency.

### Kubernetes and Helm Charts
In containerized environments orchestrated by Kubernetes, Helm charts emerge as a convenient solution for deploying and managing PostgreSQL instances. 

### Optimizing Resource Utilization
Tanzu's integration optimizes resource utilization by ensuring efficient use of underlying infrastructure. The Tanzu infrastructure, in conjunction with PostgreSQL's HA failover mechanism, creates a symbiotic relationship where resources are allocated dynamically, contributing to cost-effectiveness and performance optimization.


In this example, we'll walk through the installation and configuration steps for achieving High Availability failover in PostgreSQL using Helm charts, Kubernetes, and Replication Manager within the Tanzu infrastructure. We've set up two namespaces, `primary` and `standby`, with the goal that if the primary node goes down, the standby node seamlessly takes over.

## Supported Component Matrix
The following component versions and interoperability matrix are supported with this deployment:

- **Backend Tanzu Infrastructure**: Configured with Tanzu Kubernetes Grid 2.3.0
- **Helm version**: v3.8.1
- **vCenter**: 8.0.2(22617221)
- **NSX**: 4.1.0.2(21761691)
- **Kubernetes**: v1.25.6

## Installation

1. Add an Helm repository.

    ```bash
    # helm repo add bitnami https://charts.bitnami.com/bitnami
    "bitnami" has been added to your repositories
    ```

1. Create the following Kubernetes namespaces.
    ```bash
    # kubectl create ns primary
    # kubectl create ns standby
    ```

1. Deploy the primary node. You can download the sample `primary-values.yaml` file from [here](./resources/postgres-sql/primary-values.yaml).
    ```bash
    # helm install primary-repmgr oci://registry-1.docker.io/bitnamicharts/postgresql-ha -n primary -f values-primary.yaml
    NAME: primary-repmgr
    LAST DEPLOYED: Thu Jan  4 09:45:02 2024
    NAMESPACE: primary
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    CHART NAME: postgresql-ha
    CHART VERSION: 12.3.7
    APP VERSION: 16.1.0
    ```

1. Deploy the standby node. You can download the sample `standby-values.yaml` file from [here](./resources/postgres-sql/standby-values.yaml).
    ```bash
    # helm install standby-repmgr oci://registry-1.docker.io/bitnamicharts/postgresql-ha -n standby -f values-standby.yaml
    NAME: standby-repmgr
    LAST DEPLOYED: Thu Jan  4 09:49:00 2024
    NAMESPACE: standby
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    CHART NAME: postgresql-ha
    CHART VERSION: 12.3.7
    APP VERSION: 16.1.0
    ```

1. Scale down the nodes.
    ```bash
    # kubectl scale sts/primary-repmgr-postgresql-ha-postgresql --replicas=0 -n primary
    statefulset.apps/primary-repmgr-postgresql-ha-postgresql scaled
    # kubectl scale sts/standby-repmgr-postgresql-ha-postgresql --replicas=0 -n standby
    statefulset.apps/standby-repmgr-postgresql-ha-postgresql scaled
    ```

1. Configure the Replication Manager.
    ```bash
    # kubectl edit sts/primary-repmgr-postgresql-ha-postgresql -n primary
    …
            - name: REPMGR_PARTNER_NODES
            value: <primary-svc-name>.svc.cluster.local,<standby-svc-name>svc.cluster.local,
            - name: REPMGR_PRIMARY_HOST
            value: <primary-svc-name>.svc.cluster.local
    …
    ```
    > **Note** 
        Update the parameters `REPMGR_PARTNER_NODES`, `REPMGR_PRIMARY_HOST` to reflect the cluster's topology.

    > **Note**
        In the scenario described above, the testing involves interactions between distinct namespaces. As a result, we utilized `svc.cluster.local` to address the nodes. If you're setting up PostgreSQL nodes in separate clusters, it is mandatory to update the addressing information with either the Fully Qualified Domain Name (FQDN) or the IP address corresponding to each node in the respective clusters.

    ```bash
    # kubectl edit sts/standby-repmgr-postgresql-ha-postgresql -n standby
    …
            - name: REPMGR_PARTNER_NODES
            value: <primary-svc-name>.svc.cluster.local,<standby-svc-name>svc.cluster.local,
            - name: REPMGR_PRIMARY_HOST
            value:   <primary-svc-name>.svc.cluster.local
    …
    ```

1. Update the primary PGPool.

    ```bash
    # kubectl edit deployments primary-repmgr-postgresql-ha-pgpool -n primary
    …
    - name: PGPOOL_BACKEND_NODES
            value: 0:primary-repmgr-postgresql-ha-postgresql-0.<primary-svc-name>:5432,1:standby-repmgr-postgresql-ha-postgresql-0.<standby-svc-name>:5432,
    …
    ```

    > **Note**  Update the `PGPOOL_BACKEND_NODES` parameter to recognize the new primary and standby nodes.

1. Update the standby PGPool.

    ```bash
    # kubectl edit deployments standby-repmgr-postgresql-ha-pgpool -n standby
    ..
    - name: PGPOOL_BACKEND_NODES
        value: 0:primary-repmgr-postgresql-ha-postgresql-0.<primary-svc-name>:5432,1:standby-repmgr-postgresql-ha-postgresql-0.<standby-svc-name>:5432,
    …
    ```
 
1. Configure the pg_hba.conf file by updating the ConfigMap for Standby.

    ```bash
    # kubectl edit cm standby-repmgr-postgresql-ha-postgresql-hooks-scripts -n standby
    ..
    data:
    pg_hba.conf: |
        host     replication     postgres        0.0.0.0/0               trust
        host     replication     repl_user       0.0.0.0/0               trust
        host     replication     repl_user       0.0.0.0/0               md5
        host     all             all             0.0.0.0/0               md5
        host     all             all             ::/0                    md5
        local    all             all                                     md5
        host     all             all        127.0.0.1/32                 md5
        host     all             all        ::1/128                      md5
    …
    ```
    > **Note** Update the `pg_hba.conf` file to allow necessary host connections for replication, ensuring secure communication between the nodes.

1. Initiate Failover.  <br>
To initiate the failover, the primary node is gracefully scaled down to zero replicas, allowing the standby node in a different namespace to take over seamlessly so that we can verify it by checking the `kubectl` logs

    ```bash
    # kubectl scale sts/primary-repmgr-postgresql-ha-postgresql --replicas=0 -n primary
    statefulset.apps/primary-repmgr-postgresql-ha-postgresql scaled
    ```
    The standby node in the 'standby' namespace will take over seamlessly.

1. Verify Logs. 

    ```bash
    # kubectl logs standby-repmgr-postgresql-ha-postgresql-0 -n standby
    …
    DEBUG: begin_transaction()
    DEBUG: commit_transaction()
    NOTICE: STANDBY PROMOTE successful
    DETAIL: server "standby-repmgr-postgresql-ha-postgresql-0" (ID: 1006) was successfully promoted to primary
    DEBUG: _create_event(): event is "standby_promote" for node 1006
    DEBUG: get_recovery_type(): SELECT pg_catalog.pg_is_in_recovery()
    DEBUG: _create_event():
    INSERT INTO repmgr.events (              node_id,              event,              successful,              details             )       VALUES ($1, $2, $3, $4)    RETURNING event_timestamp
    DEBUG: _create_event(): Event timestamp is "2024-01-04 14:03:37.316107+00"
    DEBUG: _create_event(): command is '/opt/bitnami/repmgr/events/router.sh %n %e %s "%t" "%d"'
    INFO: executing notification command for event "standby_promote"
    DETAIL: command is:
    /opt/bitnami/repmgr/events/router.sh 1006 standby_promote 1 "2024-01-04 14:03:37.316107+00" "server \"standby-repmgr-postgresql-ha-postgresql-0\" (ID: 1006) was successfully promoted to primary"
    DETAIL: parsed event notification command was:
    /opt/bitnami/repmgr/events/router.sh 1006 standby_promote 1 "2024-01-04 14:03:37.316107+00" "server \"standby-repmgr-postgresql-ha-postgresql-0\" (ID: 1006) was successfully promoted to primary"
    …

    ```
    Check the logs to ensure that the standby node has been successfully promoted to the primary role.

By following these steps, you've set up a PostgreSQL High Availability (HA) failover system using Helm charts and Kubernetes with Tanzu infrastructure. This ensures continuous database accessibility and data integrity, even in the face of unexpected failures. The automated failover capabilities provided by Replication Manager (repmgr) further enhance the reliability of your PostgreSQL deployment in containerized environments.

## Benefits of PostgreSQL HA Failover

The PostgreSQL HA failover mechanism enables the following benefits:

- **Continuous Availability**: HA failover stands as the bedrock of ensuring continuous accessibility to the PostgreSQL database. In the event of a primary node failure, the failover mechanism swiftly transitions to a standby node, ensuring uninterrupted service for both applications and users. This continuous availability is paramount for applications that demand high uptime and reliability.
- **Data Integrity**: The replication mechanism employed by PostgreSQL guarantees that the standby node is always up-to-date with the primary node. This synchronization minimizes the risk of data loss, providing a safety net in the face of unforeseen circumstances such as a primary node failure. Data integrity is thus maintained, offering peace of mind to administrators and users alike.
- **Automated Management**: The repmgr, an important tool in PostgreSQL's HA toolkit, takes the lead in automating the failover process. By constantly monitoring the health of the primary node, repmgr triggers the promotion of a standby node to the new primary node upon detection of a failure. This automated management significantly reduces the need for manual intervention, ensuring that failover occurs swiftly and efficiently. The result is a streamlined process that minimizes downtime and optimizes the overall database management experience.
- **Scalability**: Kubernetes and Helm charts add a layer of scalability to PostgreSQL deployments. These tools facilitate the easy addition or removal of nodes as per the evolving needs of the application. Scalability is a crucial factor in modern IT infrastructure, allowing organizations to adapt to changing workloads, optimize resource utilization, and ensure that the database can scale seamlessly with the growth of the business.

## Summary
By integrating Tanzu infrastructure into our PostgreSQL High Availability (HA) failover solution within the dynamic realm of containerized environments, PostgreSQL's HA failover mechanisms, orchestrated through Kubernetes and Helm, extend beyond simple failover capabilities. <br> 
They provide the following comprehensive suite of benefits that cater to the demands of modern applications:


- **Reliability**: Continuous availability and automated failover ensure that the database remains reliable, even in the face of unexpected challenges.
- **Resilience**: Data integrity is not just a feature but a foundational principle, safeguarding against potential data loss and ensuring a robust and resilient database infrastructure.
- **Efficiency**: The automated management provided by repmgr reduces the burden on administrators, allowing them to focus on strategic tasks rather than firefighting during downtime.
- **Flexibility**: Scalability, enabled by Kubernetes and Helm charts, adds a layer of flexibility. PostgreSQL deployments can effortlessly adapt to changing workloads and resource requirements, aligning with the dynamic nature of modern business operations. <br>

In essence, the benefits ensure that PostgreSQL not only withstands node failures but also emerges as a resilient, high-performance, and adaptable database solution, ready to meet the challenges.
