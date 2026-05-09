# ClusterAPI - CAPMOX + Talos

## Create Talos template and management cluster
```shell
cd terraform
terraform init -backend-config=mgmt.config
terraform apply -var-file=mgmt.tfvars
terraform output -raw kubeconfig > mgmt
```

## Create user/token
```shell
pveum user add capmox@pve
pveum user token add capmox@pve capi --privsep 1
pveum role add Terraform -privs "Realm.AllocateUser, VM.PowerMgmt, VM.GuestAgent.Unrestricted, Sys.Console, Sys.Audit, Sys.AccessNetwork, VM.Config.Cloudinit, VM.Replicate, Pool.Allocate, SDN.Audit, Realm.Allocate, SDN.Use, Mapping.Modify, VM.Config.Memory, VM.GuestAgent.FileSystemMgmt, VM.Allocate, SDN.Allocate, VM.Console, VM.Clone, VM.Backup, Datastore.AllocateTemplate, VM.Snapshot, VM.Config.Network, Sys.Incoming, Sys.Modify, VM.Snapshot.Rollback, VM.Config.Disk, Datastore.Allocate, VM.Config.CPU, VM.Config.CDROM, Group.Allocate, Datastore.Audit, VM.Migrate, VM.GuestAgent.FileWrite, Mapping.Use, Datastore.AllocateSpace, Sys.Syslog, VM.Config.Options, Pool.Audit, User.Modify, VM.Config.HWType, VM.Audit, Sys.PowerMgmt, VM.GuestAgent.Audit, Mapping.Audit, VM.GuestAgent.FileRead, Permissions.Modify"
pveum aclmod / --users capmox@pve --roles Terraform
pveum aclmod / --tokens "capmox@pve!capi" --roles Terraform
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