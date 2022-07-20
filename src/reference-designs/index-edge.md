# VMware Tanzu Edge Solution Reference Architecture 1.0
Edge computing is gaining a lot of momentum for a variety of reasons that range from avoidance of latency, data volume, and bandwidth considerations to the need for autonomous disconnected operations, privacy, and security. These reasons are pushing businesses across all industries to run more and more applications at edge sites. Traditionally, these applications are run on VMs, but with the emergence of Kubernetes and microservices architectures, more applications are being containerized and there is a need for running a cloud native compute stack at the edge.

For enterprises that already have remote offices and branch offices with a few servers running edge workloads, running modern, distributed applications across your edge sites can add a new layer of complexity. There is a significant difference between running a cloud native platform at the core data center versus running it at edge sites.

The VMware Edge Compute Stack helps enterprises manage their edge sites with little or no local IT staff and enables them to run VM workloads at these sites. With the addition of VMware Tanzu, you can simplify how you architect and deploy a cloud native stack at hundreds or thousands of edge sites so that you can run cloud native applications at the edge.

The Tanzu design for VMware Edge Compute Stack described here offers a best practice for running Tanzu at edge sites where the VMware Edge Compute Stack is already deployed. We will specifically address the following challenges at the edge:

- Running and managing Kubernetes infrastructure
- Providing a consistent development and deployment environment for applications across the cloud, datacenter, and edge
- Managing a fleet of Kubernetes clusters
- Proactively monitoring clusters and apps
- Ensuring security and compliance of edge environments.

On top of the VMware Edge Compute Stack, the VMware Tanzu Edge Solution Architecture comprises core VMware Tanzu capabilities, including:

- Unified Kubernetes Runtime: VMware Tanzu Kubernetes Grid (TKG) provides a consistent, upstream-compatible implementation of Kubernetes, that is tested, signed, and supported by VMware.
- Global Multi-Cluster Management: VMware Tanzu Mission Control (TMC) is a centralized management platform for consistently operating and securing your Kubernetes infrastructure and modern applications across multiple teams and clouds, regardless of where they reside.
- Full-Stack Observability: VMware Tanzu Observability by Wavefront (TO) is a high-performance streaming analytics platform that supports 3D observability (metrics, histograms, traces/spans). You can collect data from many services and sources across your entire application stack, including edge sites.