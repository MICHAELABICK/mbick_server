let networking = ../../networking/types.dhall

in {
, ssh_username : networking.SSHUsername
, proxmox_user : ./ProxmoxUser.dhall
, duckdns-token : Text
}
