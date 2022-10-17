
resource "oci_core_network_security_group" "control_plane" {
  compartment_id = var.compartment_id
  vcn_id         = var.create_vcn ? module.vcn[0].vcn_id : var.existing_vcn_id
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
  display_name   = "tkg.cloud.vmware.com/control_plane"
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_internet" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "EGRESS"
  protocol                  = "all"
  description               = "Control Plane Nodes access to Internet"

  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "load_balancer_to_apiserver" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "Kubernetes API endpoint, allow ingress from the control plane endpoint"

  source      = oci_core_network_security_group.control_plane_endpoint.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_to_apiserver" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Kubernetes API endpoint, allow ingress for worker nodes"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "etcd_client" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "etcd client communication"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range{
      max = 2379
      min = 2379
    }
  }
}

resource "oci_core_network_security_group_security_rule" "etcd_peer" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "etcd peer communication"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 2380
      min = 2380
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_to_control_plane_antrea" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Antrea service, allow ingress for worker nodes"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 10349
      min = 10349
    }
  }
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_control_plane_antrea" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Antrea service, allow ingress for control plane nodes"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 10349
      min = 10349
    }
  }
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_control_plane_kubelet" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Control Plane to Control Plane Kubelet Communication"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 10250
      min = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_control_plane_geneve" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "17"

  description = "Control plane to Geneve Service"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  udp_options {
    destination_port_range {
      max = 6081
      min = 6081
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_to_control_plane_geneve" {
  network_security_group_id = oci_core_network_security_group.control_plane.id
  direction                 = "INGRESS"
  protocol                  = "17"

  description = "Worker node to Geneve Service"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  udp_options {
    destination_port_range {
      max = 6081
      min = 6081
    }
  }
}

//
// NSG for worker nodes
//

resource "oci_core_network_security_group" "workers" {
  compartment_id = var.compartment_id
  vcn_id         = var.create_vcn ? module.vcn[0].vcn_id : var.existing_vcn_id
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
  display_name   = "Worker Security Group"
}

resource "oci_core_network_security_group_security_rule" "workers_to_internet" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "EGRESS"
  protocol                  = "all"

  description = "Worker Nodes access to Internet"

  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_workers_kubelet" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Control plane nodes to worker node Kubelet Communication"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 10250
      min = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "node_port_services_tcp" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Worker node to default NodePort ingress communication"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 32767
      min = 30000
    }
  }
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_workers_geneve" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  protocol                  = "17"

  description = "Control plane to GENEVE protocol"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  udp_options {
    destination_port_range {
      max = 6081
      min = 6081
    }
  }
}

resource "oci_core_network_security_group_security_rule" "worker_to_worker_geneve" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  protocol                  = "17"

  description = "Worker node to Geneve Service"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  udp_options {
    destination_port_range {
      max = 6081
      min = 6081
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_to_workers_antrea" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Antrea service, allow ingress for worker nodes"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 10349
      min = 10349
    }
  }
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_workers_antrea" {
  network_security_group_id = oci_core_network_security_group.workers.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Antrea service, allow ingress for control plane nodes"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 10349
      min = 10349
    }
  }
}


//
// NSG for control plane endpoint
//

resource "oci_core_network_security_group" "control_plane_endpoint" {
  compartment_id = var.compartment_id
  vcn_id         = var.create_vcn ? module.vcn[0].vcn_id : var.existing_vcn_id
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
  display_name   = "Control Plane Endpoint Security Group"
}

resource "oci_core_network_security_group_security_rule" "everywhere_to_apiserver" {
  network_security_group_id = oci_core_network_security_group.control_plane_endpoint.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "External access to Kubernetes API endpoint"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "control_plane_to_load_balancer_kubernetes" {
  network_security_group_id = oci_core_network_security_group.control_plane_endpoint.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Kubernetes API traffic to Control Plane"

  source      = oci_core_network_security_group.control_plane.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    source_port_range {
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "load_balancer_to_control_plane_kubernetes" {
  network_security_group_id = oci_core_network_security_group.control_plane_endpoint.id
  direction                 = "EGRESS"
  protocol                  = "6"

  description = "Kubernetes API traffic to Control Plane"

  destination      = oci_core_network_security_group.control_plane.id
  destination_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}


resource "oci_core_network_security_group_security_rule" "workers_to_load_balancer_kubernetes" {
  network_security_group_id = oci_core_network_security_group.control_plane_endpoint.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "Kubernetes API traffic to Control Plane"

  source      = oci_core_network_security_group.workers.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      max = 6443
      min = 6443
    }
  }
}
