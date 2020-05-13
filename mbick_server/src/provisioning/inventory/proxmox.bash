#!/bin/bash

set -e

# change directory to location of this script
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
PROJECT_DIR="$(cd "${SRC_DIR}/../.."; pwd)"
VENDOR_DIR="$(cd "${PROJECT_DIR}/../../vendor"; pwd)"
SCRIPT_DIR="$VENDOR_DIR/github.com/MICHAELABICK/Ansible-Proxmox-inventory"

eval $(dhall-to-bash --declare VAULT_API_URL <<< \
  "let packages = ${PROJECT_DIR}/packages.dhall in packages.mbick-server.ansible.vault_api_url")
eval $(dhall-to-bash --declare PROXMOX_API_URL <<< \
  "let packages = ${PROJECT_DIR}/packages.dhall in packages.mbick-server.ansible.proxmox_api_url")

PROXMOX_USERNAME=$(vault kv get -address=$VAULT_API_URL -field=username proxmox_user/ansible-inventory)
PROXMOX_PASSWORD=$(vault kv get -address=$VAULT_API_URL -field=password proxmox_user/ansible-inventory)

python "$SCRIPT_DIR/proxmox.py" \
    --url="$PROXMOX_API_URL" \
    --username="$PROXMOX_USERNAME" \
    --password="$PROXMOX_PASSWORD" \
    --qemu-default-interface \
    --trust-invalid-certs \
    --pretty $@
