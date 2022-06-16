# The Supervisor Cluster fails to come online

The Supervisor Cluster provisioning process is orchestrated by vCenter itself. When a new Supervisor Cluster is created on the Workload Management pane, the `wcp` service in the vCenter appliance initiates a workflow that confirms credentials, uses the ESX Agent Manager to provision the control plane VMs, and monitors the configuration of Kubernetes components within the control plane as well as the creation of any load balancer VIPs assigned to the cluster.

Unfortunately, the UI does not provide a view into this process. To troubleshoot this process for yourself, you will need to SSH into the vCenter appliance and watch the following logs:

- `/var/log/vmware/wcp/wcpsvc.log`
- `/var/log/vmware/vpxd/vpxd.log`.

If you are using Avi as your load balancer, you can also view the log files within `/opt/avi/log` to view information about Service Engine provisioning and VIP assignment.

Some common causes for the Supervisor Cluster to fail to come up include:
- Lack of resources within the vSphere cluster into which Supervisor Cluster control plane VMs are
  being placed
- Incorrect Avi credentials or certificate
- An invalid IPAM profile was provided to the Avi Service Engine group
- Firewall rules preventing TCP/6443 within the management cluster network from being reachable
  within the Cluster VIP or Avi networks.