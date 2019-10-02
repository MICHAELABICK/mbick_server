let Prelude = ../config/Prelude.dhall

let paths = ../paths.dhall

let types = ../config/types.dhall
let defaults = ../config/defaults.dhall
let credentials = ../config/credentials.dhall


let Location = < Environment : Text | Local : Text | Missing | Remote : Text >

let proxmox_user = credentials.proxmox_user

in
{ ansible_dir = paths.ansible
, ansible_inventory_dir = paths.ansible_inventory
, proxmox_api_host = defaults.proxmox_api_host
, proxmox_api_url = defaults.proxmox_api_url
, proxmox_user = proxmox_user.username
, proxmox_password = proxmox_user.password
} :
-- TODO: use Location schema once it is released in Prelude v11
-- { ansible_dir : Prelude.Location
-- , ansible_inventory_dir : Prelude.Location
{ ansible_dir : Location
, ansible_inventory_dir : Location
, proxmox_api_host : types.HostAddress
, proxmox_api_url : types.ProxmoxApiUrl
, proxmox_user : types.ProxmoxUsername
, proxmox_password : types.ProxmoxPassword
}
