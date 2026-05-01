#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_VM_ID=2222
NAME="talos-template"
STORAGE="p1_nvme"
BRIDGE="vmbr0"
NODE="pve"
TALOS_VERSION="v1.12.7"

TOKEN_USER="capmox@pve"
TOKEN_ID="capi"
FULL_TOKEN_ID="${TOKEN_USER}!${TOKEN_ID}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

which jq > /dev/null
if [ $? == 1 ]; then
    apt-get -y -qq install jq
fi

pveum user add "$TOKEN_USER"
pveum aclmod / --users "$TOKEN_USER" --roles Administrator

token_json="$(
  pveum user token add "$TOKEN_USER" "$TOKEN_ID" --privsep 1 --output-format json
)"

token_full_id="$(printf '%s\n' "$token_json" | jq -r '."full-tokenid"')"
token_secret="$(printf '%s\n' "$token_json" | jq -r '.value')"

pveum aclmod / --tokens "$FULL_TOKEN_ID" --roles Administrator

cd "$WORKDIR"

wget -O talos.raw.gz -q \
  "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/${TALOS_VERSION}/nocloud-amd64.raw.gz"

gunzip talos.raw.gz

if qm status "$TEMPLATE_VM_ID" >/dev/null 2>&1; then
  qm stop "$TEMPLATE_VM_ID" 2>/dev/null || true
  qm destroy "$TEMPLATE_VM_ID" --purge
fi

qm create "$TEMPLATE_VM_ID" \
  --name "$NAME" \
  --memory 4096 \
  --cores 2 \
  --sockets 1 \
  --net0 "virtio,bridge=${BRIDGE}" \
  --scsihw virtio-scsi-single \
  --cpu x86-64-v2-AES

qm importdisk "$TEMPLATE_VM_ID" talos.raw "$STORAGE"
qm set "$TEMPLATE_VM_ID" \
  --scsi0 "${STORAGE}:vm-${TEMPLATE_VM_ID}-disk-0,discard=on,iothread=on,ssd=on"
qm resize "$TEMPLATE_VM_ID" scsi0 +20G
qm set "$TEMPLATE_VM_ID" --boot order='scsi0;net0'
qm template "$TEMPLATE_VM_ID"

cat <<EOF

Done

PROXMOX_TOKEN: "${token_full_id}"
PROXMOX_SECRET: "${token_secret}"

EOF