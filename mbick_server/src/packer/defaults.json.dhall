let defaults = ../../config/defaults.dhall
let credentials = ../../config/credentials.dhall

in
{ ansible_dir = defaults.ansible_dir
, ansible_inventory_dir = defaults.ansible_inventory_dir
, proxmox_api_host = defaults.proxmox_api_host
, proxmox_api_url = defaults.proxmox_api_url
, proxmox_user = credentials.proxmox_user
, proxmox_password = credentials.proxmox_password
}
