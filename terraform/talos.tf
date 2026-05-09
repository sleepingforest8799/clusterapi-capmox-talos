resource "talos_machine_secrets" "this" {
  talos_version = var.talos.version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos.cluster_name
  cluster_endpoint = "https://${var.talos.cp_ip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [templatefile("template/controlplane.yaml.tftpl", {
    vip = var.talos.vip
  })]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.talos.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [var.talos.cp_ip]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [resource.proxmox_virtual_environment_vm.controlplane]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = var.talos.cp_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos.cp_ip
}

data "talos_cluster_health" "available" {
  depends_on = [resource.proxmox_virtual_environment_vm.controlplane, resource.talos_machine_bootstrap.this]

  client_configuration   = talos_machine_secrets.this.client_configuration
  control_plane_nodes    = [var.talos.cp_ip]
  endpoints              = [var.talos.cp_ip]
  skip_kubernetes_checks = true

  timeouts = {
    read = "15m"
  }
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos.cp_ip
}