variable "pve" {
  type = object({
    endpoint          = string
    api_token         = string
    username          = string
    private_key       = string
    node_name         = string
    vm_id             = string
    template_vm_id    = number
    storage_disks     = string
    storage_cloudinit = string
    cp_mem            = number
    dns_domain        = string
    dns_server        = string
    vlan_id           = number
    gateway           = string
  })
}

variable "talos" {
  type = object({
    cluster_name = string
    cp_ip        = string
    vip          = string
    version      = string
  })
}
