let types = ../types.dhall

let config = ../config.dhall


in  { ansible_dir =
        config.project_paths.ansible
    , ansible_inventory_dir =
        config.project_paths.ansible_inventory
    , proxmox_api_host =
        defaults.proxmox_api_host
    , proxmox_api_url =
        defaults.proxmox_api_url
    , proxmox_user =
        credentials.proxmox_user.username
    , proxmox_password =
        credentials.proxmox_user.password
    } :
    -- TODO: use Location schema once it is released in Prelude v11
    -- { ansible_dir : Prelude.Location
    -- , ansible_inventory_dir : Prelude.Location
    { ansible_dir : types.AbsoluteFilePath
    , ansible_inventory_dir : types.AbsoluteFilePath
    , proxmox_api_host : types.HostAddress
    , proxmox_api_url : types.ProxmoxAPIURL
    , proxmox_user : types.ProxmoxUsername
    , proxmox_password : types.ProxmoxPassword
    }
