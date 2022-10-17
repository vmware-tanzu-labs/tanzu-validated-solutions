locals {
  tanzu_tags = {
    "CreatedBy" = "tkg.cloud.vmware.com"
  }

  freeform_tags = var.enable_tanzu_freeform_tags ? merge(var.freeform_tags, local.tanzu_tags) : var.freeform_tags
}
