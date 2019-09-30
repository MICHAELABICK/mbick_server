let Prelude = ../../config/Prelude.dhall

let types = ../../config/types.dhall
let defaults = ../../config/defaults.dhall
let credentials = ../../config/credentials.dhall


let proxmox_user = credentials.proxmox_user

in
{ ansible_dir = defaults.ansible_dir
, ansible_inventory_dir = defaults.ansible_inventory_dir
, proxmox_api_host = defaults.proxmox_api_host
, proxmox_api_url = defaults.proxmox_api_url
, proxmox_user = proxmox_user.username
, proxmox_password = proxmox_user.password
} :
-- TODO: use Location schema once it is released in Prelude v11
-- { ansible_dir : Prelude.Location.Local
-- , ansible_inventory_dir : Prelude.Location.Local
{ ansible_dir : Text
, ansible_inventory_dir : Text
, proxmox_api_host : types.HostAddress
, proxmox_api_url : types.ProxmoxApiUrl
, proxmox_user : types.ProxmoxUsername
, proxmox_password : types.ProxmoxPassword
}
