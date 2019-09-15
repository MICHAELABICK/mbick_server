#!/bin/bash

set -e

# change directory to location of this script
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
PROJECT_DIR="$(cd "${SRC_DIR}/../.."; pwd)"
# SCRIPT_DIR="$PROJECT_DIR/vendor/ansible-proxmox-inventory"
SCRIPT_DIR="$PROJECT_DIR/vendor/github.com/RaSerge/ansible-proxmox-inventory"

PROXMOX_URL=$(/bin/bash "$PROJECT_DIR/scripts/parse_env_file" \
    "$PROJECT_DIR/common.env" PROXMOX_URL)"/"
PROXMOX_USERNAME=$(/bin/bash "$PROJECT_DIR/scripts/parse_env_file" \
    "$PROJECT_DIR/defaults.env" PROXMOX_USER)
PROXMOX_PASSWORD=$(/bin/bash "$PROJECT_DIR/scripts/parse_env_file" \
    "$PROJECT_DIR/defaults.env" PROXMOX_PASSWORD)

python "$SCRIPT_DIR/proxmox.py" \
    --url="$PROXMOX_URL" \
    --username="$PROXMOX_USERNAME" \
    --password="$PROXMOX_PASSWORD" \
    --qemu_interface=ens18 \
    --trust-invalid-certs \
    --list --pretty
