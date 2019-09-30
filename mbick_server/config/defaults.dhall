let types = ./types.dhall


let project_dir =
  ../build as Location
let ansible_dir =
  ../build/provision as Location
let ansible_inventory_dir =
  ../build/provision/inventory as Location

let proxmox_api_host : types.IpAddress =
  "192.178.11.101"
let proxmox_api_url_base : types.ProxmoxApiBaseUrl =
  "https://${proxmox_api_host}:8006"
let proxmox_api_url : types.ProxmoxApiUrl =
  "${proxmox_api_url_base}/api2/json"

in
{
-- directories
project_dir = project_dir
, ansible_dir = ansible_dir
, ansible_inventory_dir = ansible_inventory_dir

-- network
, gateway = "192.168.11.1"

-- proxmox
, proxmox_api_host = proxmox_api_host
, proxmox_api_url_base = proxmox_api_url_base
, proxmox_api_url = proxmox_api_url
}
