#!/bin/bash

set -e

# change directory to location of this script
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
PROJECT_DIR="$(cd "${SRC_DIR}/../.."; pwd)"
VENDOR_DIR="$PROJECT_DIR/vendor/ansible-proxmox-inventory"

export PROXMOX_URL=$(/bin/bash "$PROJECT_DIR/scripts/parse_env_file" \
    "$PROJECT_DIR/common.env" PROXMOX_URL)"/"
export PROXMOX_USERNAME=$(/bin/bash "$PROJECT_DIR/scripts/parse_env_file" \
    "$PROJECT_DIR/defaults.env" PROXMOX_USER)
export PROXMOX_PASSWORD=$(/bin/bash "$PROJECT_DIR/scripts/parse_env_file" \
    "$PROJECT_DIR/defaults.env" PROXMOX_PASSWORD)

python "$VENDOR_DIR/proxmox.py" \
    --trust-invalid-certs \
    $*

# python "$VENDOR_DIR/proxmox.py" \
#     --url="$PROXMOX_URL" \
#     --username="$PROXMOX_USERNAME" \
#     --password="$PROXMOX_PASSWORD" \
#     --list --pretty
