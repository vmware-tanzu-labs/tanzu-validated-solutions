data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "part-handler"
    content      = templatefile("${path.module}/part-handler.py.tftpl", local.cloud_init)
  }

  part {
    content_type = "cloud-config"
    content      = templatefile("${path.module}/cloud.tftpl", local.cloud_init)
  }

  dynamic "part" {
    for_each = local.cluster_types
    content {
      content_type = "text/tanzu"
      filename     = "config-${part.value}.yaml"
      content = templatefile("${path.module}/config.yaml.tftpl", merge(local.cloud_yaml, {
        AZURE-CONTROL-PLANE-SUBNET-CIDR = local.cloud_yaml["AZURE-CONTROL-PLANE-SUBNET-CIDR-${part.value}"],
        AZURE-CONTROL-PLANE-SUBNET-NAME = local.cloud_yaml["AZURE-CONTROL-PLANE-SUBNET-NAME-${part.value}"],
        AZURE-NODE-SUBNET-CIDR          = local.cloud_yaml["AZURE-NODE-SUBNET-CIDR-${part.value}"],
        AZURE-NODE-SUBNET-NAME          = local.cloud_yaml["AZURE-NODE-SUBNET-NAME-${part.value}"]
      }))
    }
  }
}

data "azurerm_key_vault_secrets" "this" {
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_secret" "this" {
  for_each = toset(data.azurerm_key_vault_secrets.this.names)

  name         = each.key
  key_vault_id = data.azurerm_key_vault.this.id
}