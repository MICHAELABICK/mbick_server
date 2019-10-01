let types = ./types.dhall


let proxmoxApiBaseUrl : types.HostAddress -> types.ProxmoxApiBaseUrl =
      \(host : types.HostAddress)
  ->  let address : Text =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006"
let proxmoxApiUrl : types.HostAddress -> types.ProxmoxApiUrl =
      \(host : types.HostAddress)
  ->  let base : Text = proxmoxApiBaseUrl host in "${base}/api2/json"

let proxmox_api_host = types.HostAddress.IP "192.178.11.101"

in
{ gateway = "192.168.11.1"
, proxmox_api_host = proxmox_api_host
, proxmox_api_base_url = proxmoxApiBaseUrl proxmox_api_host
, proxmox_api_url = proxmoxApiUrl proxmox_api_host
}
