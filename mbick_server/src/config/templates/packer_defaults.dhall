let types = ../types.dhall
let config = ../config.dhall


let project_paths = config.project_paths
let proxmox_api = config.proxmox_api
let credentials = config.credentials

in  { ansible_dir =
        project_paths.ansible
    , ansible_inventory_dir =
        project_paths.ansible_inventory
    , proxmox_api_host =
        proxmox_api.host
    , proxmox_api_url =
        proxmox_api.url
    , proxmox_user =
        credentials.proxmox_user.user
    , proxmox_password =
        credentials.proxmox_user.password
    } :
    { ansible_dir : Location
    , ansible_inventory_dir : Location
    , proxmox_api_host : types.HostAddress
    , proxmox_api_url : types.ProxmoxAPIURL
    , proxmox_user : types.ProxmoxUsername
    , proxmox_password : types.ProxmoxPassword
    }
