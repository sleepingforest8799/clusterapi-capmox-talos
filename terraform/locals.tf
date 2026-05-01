locals {
  cp_ip     = [for i in range(var.talos.cp_count) : cidrhost(var.pve.cidr, var.talos.cp_octet + i)]
}

