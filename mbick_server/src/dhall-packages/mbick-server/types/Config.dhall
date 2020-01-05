let networking = ../../networking/types.dhall

in {
, project_paths :
    ./ProjectPaths.dhall
, proxmox_api :
    ./ProxmoxAPI.dhall
, gateway :
    networking.IPAddress
, vault_api :
    ./HashicorpVaultAPI.dhall
}
