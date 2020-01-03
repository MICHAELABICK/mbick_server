let networking = ../../networking/types.dhall

in {
, project_paths :
    ./ProjectPaths.dhall
, credentials :
    ./Credentials.dhall
, proxmox_api :
    ./ProxmoxAPI.dhall
, gateway :
    networking.IPAddress
}
