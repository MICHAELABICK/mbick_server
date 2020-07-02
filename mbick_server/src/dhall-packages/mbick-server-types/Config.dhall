let networking = ../networking/package.dhall

in {
, project_paths :
    ./ProjectPaths.dhall
, proxmox_api :
    ./ProxmoxAPI.dhall
, gateway :
    networking.IPAddress
, subnet :
    networking.Subnet
, vault_api :
    ./HashicorpVaultAPI.dhall
}
