resource "proxmox_download_file" "talos_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.pve.node_name

  url                     = "https://factory.talos.dev/image/ca757c5bc571372976cf96c116ff9c22362d7226dcc5b7feb140bd53a71aae32/${var.talos.version}/nocloud-amd64.raw.gz"
  file_name               = "talos-nocloud-amd64-${var.talos.version}.img"
  decompression_algorithm = "gz"
}

resource "proxmox_virtual_environment_vm" "template" {
  name      = "talos-template-${var.talos.version}"
  tags      = ["talos"]
  node_name = var.pve.node_name
  vm_id     = var.pve.template_vm_id

  template = true

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.pve.cp_mem
  }

  disk {
    datastore_id = var.pve.storage_disks
    file_id      = proxmox_download_file.talos_image.id
    discard      = "on"
    ssd          = true
    interface    = "scsi0"
    size         = 30
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  name      = "talos-mgmt"
  tags      = ["talos", "${var.talos.cluster_name}"]
  node_name = var.pve.node_name
  vm_id     = var.pve.vm_id

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.pve.cp_mem
  }

  disk {
    datastore_id = var.pve.storage_disks
    file_id      = proxmox_download_file.talos_image.id
    discard      = "on"
    ssd          = true
    interface    = "scsi0"
    size         = 30
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.pve.vlan_id
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = var.pve.storage_cloudinit
    ip_config {
      ipv4 {
        address = "${var.talos.cp_ip}/24"
        gateway = var.pve.gateway
      }
    }
    dns {
      servers = [var.pve.dns_server]
      domain  = var.pve.dns_domain
    }
  }
}
