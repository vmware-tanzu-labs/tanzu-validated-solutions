# Management and Monitoring

Tanzu GemFire provides powerful tools for managing and monitoring your distributed data grid environment. The two primary tools are the GFSH command-line interface and the Tanzu GemFire Management Console (GMC)**.

## GFSH Command-Line Tool

The GemFire Shell (gfsh) is the recommended command-line interface for configuring, managing and monitoring the Tanzu GemFire cluster. It allows you to:

* Start and stop locators and cache servers
* Create, modify, or destroy regions
* Deploy and manage application JARs
* Execute user-defined functions
* Manage disk stores and perform data import/export
* Monitor members and system metrics
* Launch monitoring tools and shut down the cluster
* Save and manage shared cluster configurations

GFSH can be run in its own interactive shell or invoked from the operating system's command line. It supports scripting for automation and can connect to remote clusters using HTTP. With shared configuration support, GFSH enables defining reusable settings across the cluster, which are stored and synchronized by locators in files like cluster.xml and cluster.properties.
More information on GFSH refer:

* [Running gfsh Commands on the OS Command Line](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-GemFire/10-0/gf/tools_modules-gfsh-os_command_line_execution.html#topic_fpf_y1g_tp)
* [Using gfsh to Manage a Remote Cluster Over HTTP or HTTPS](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-GemFire/10-0/gf/configuring-cluster_config-gfsh_remote.html)
* [Creating and Running gfsh Command Scripts](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-GemFire/10-0/gf/tools_modules-gfsh-command_scripting.html#concept_9B2F7550F16C4717831AD40A56922259)

## Tanzu GemFire Management Console

The Tanzu GemFire Management Console (GMC) is a browser-based interface that simplifies day-to-day operations and provides visual insights into your GemFire clusters. With GMC, you can:

* Monitor multiple clusters in a single UI
* View and manage regions and disk stores
* Deploy or remove JARs
* Search and analyze cluster logs
* Execute commands using a built-in web-based GFSH
* Manage WAN components like Gateway Senders
* Visualize cluster topology in real time

The console is ideal for both routine operations and troubleshooting, providing an intuitive experience for administrators.

More information on GMC refer: [https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-GemFire-management-console/1-3/gf-mc/index.html](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire-management-console/1-3/gf-mc/index.html)