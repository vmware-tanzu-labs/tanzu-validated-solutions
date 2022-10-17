locals {
  compartment_hash = sha256(var.compartment_id)
}
