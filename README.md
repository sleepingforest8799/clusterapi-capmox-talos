# ClusterAPI - CAPMOX + Talos

## Terraform values
mgmt.config
```text
bucket     = "mgmt-cluster-api" 
key        = "terraform.tfstate"
region     = "us-east-1"
endpoints  = {
    s3 = "http://s3.home.local:9000"
}
access_key=""
secret_key=""
```

mgmt.tfvars
```terraform
pve = {
  "endpoint"          = ""
  "api_token"         = ""
  "username"          = ""
  "private_key"       = ""
  "node_name"         = ""
  "name_prefix"       = ""
  "vm_id"             = 100
  "storage_disks"     = ""
  "storage_cloudinit" = ""
  "dns_domain"        = ""
  "dns_server"        = ""
  "vlan_id"           = ""
  "cidr"              = ""
  "gateway"           = ""
  "cp_mem"            = 4096
}

talos = {
  "version"      = "1.12.7"
  "cp_count"     = 1
  "environment"  = "mgmt"
  "cluster_name" = "mgmt"

  "cp_octet"     = 10 # last octet in cidr
  "endpoint"     = ""
  "vip"          = ""
}
```

## Deploy management cluster
```shell
cd terraform
terraform init -backend-config=mgmt.config
terraform apply -var-file=mgmt.tfvars
terraform output -raw kubeconfig > mgmt
```

## Create user/token, VM Talos template
```shell
ssh root@proxmox-ip 'bash -s' < init.sh
```

## ~/.cluster-api/clusterctl.yaml
```yaml
PROXMOX_URL: "https://100.64.100.100:8006"
PROXMOX_TOKEN: "capmox@pve!capi"
PROXMOX_SECRET: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
providers:
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/v0.6.11/bootstrap-components.yaml"
    type: "BootstrapProvider"

  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/v0.5.12/control-plane-components.yaml"
    type: "ControlPlaneProvider"

  - name: "proxmox"
    url: "https://github.com/ionos-cloud/cluster-api-provider-proxmox/releases/v0.8.1/infrastructure-components.yaml"
    type: "InfrastructureProvider"
```

## Init and create cluster
In management context:
```shell
clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos
kubectl apply -f prod-cluster.yaml
clusterctl describe cluster prod1
clusterctl get kubeconfig prod1 > prod
```

## Install Cilium
Change `cilium-values.yaml`, then:

```shell
kubectl --kubeconfig prod create ns cilium 

kubectl --kubeconfig prod label ns cilium \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged
helm install cilium cilium/cilium --version 1.19.1 --namespace cilium -f cilium-values.yaml --kubeconfig prod
```