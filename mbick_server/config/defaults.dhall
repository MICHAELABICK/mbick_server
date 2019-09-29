let project_dir = ../build as Location
let ansible_dir = "${project_dir}/provisioning"

let proxmox_api_host = "192.178.11.101"
let proxmox_api_url_base = "https://${proxmox_api_host}:8006"

in
{ 
-- directories
project_dir = project_dir
, ansible_dir = ansible_dir
, ansible_inventory_dir = "${ansible_dir}/inventory"

-- network
, gateway = "192.168.11.1"

-- proxmox
, proxmox_api_host = proxmox_api_host
, proxmox_api_url_base = proxmox_api_url_base
, proxmox_api_url = "${proxmox_api_url_base}/api2/json"
}
