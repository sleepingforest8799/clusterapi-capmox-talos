variable "pve" {
  type = object({
    endpoint          = string
    api_token         = string
    username          = string
    private_key       = string
    node_name         = string
    name_prefix       = string
    vm_id             = string
    storage_disks     = string
    storage_cloudinit = string
    cp_mem            = number
    dns_domain        = string
    dns_server        = string
    vlan_id           = number
    gateway           = string
    cidr              = string
  })
}

variable "talos" {
  type = object({
    cluster_name    = string
    cp_count        = number
    cp_octet        = number
    endpoint        = string
    vip             = string
    version         = string
    cilium_version  = string
  })
}
