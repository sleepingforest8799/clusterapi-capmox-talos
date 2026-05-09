terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11.0"
    }
  }

  backend "s3" {
    bucket               = ""
    key                  = ""
    workspace_key_prefix = ""

    endpoints = {}

    access_key = ""
    secret_key = ""

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "proxmox" {
  endpoint  = "https://${var.pve.endpoint}:8006/"
  api_token = var.pve.api_token
  insecure  = true

  ssh {
    username    = var.pve.username
    private_key = file(var.pve.private_key)
  }
}