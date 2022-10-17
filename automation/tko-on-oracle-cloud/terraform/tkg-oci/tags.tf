resource "oci_identity_tag_namespace" "tkg_namespace" {
  count          = var.create_tags ? 1 : 0
  compartment_id = var.compartment_id
  provider       = oci.home
  description    = "Tanzu Kubernetes Grid Namespace"
  name           = "tkg-cloud-vmware-com"

  defined_tags  = var.defined_tags
  freeform_tags = local.freeform_tags
  is_retired    = false
}

resource "oci_identity_tag" "instance_role" {
  count            = var.create_tags ? 1 : 0
  provider         = oci.home
  description      = "Instance role of nodes in a TKG cluster"
  name             = "instance-role"
  tag_namespace_id = oci_identity_tag_namespace.tkg_namespace[0].id

  defined_tags  = var.defined_tags
  freeform_tags = local.freeform_tags

  is_retired = false
}
