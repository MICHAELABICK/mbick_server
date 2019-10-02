let types = ./types.dhall


let proxmoxAPIBaseURL : types.HostAddress -> types.ProxmoxAPIBaseURL =
      \(host : types.HostAddress)
  ->  let address : Text =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006"
let proxmoxAPIURL : types.HostAddress -> types.ProxmoxAPIURL =
      \(host : types.HostAddress)
  ->  let base : Text = proxmoxAPIBaseURL host in "${base}/api2/json"


let project_paths = ../paths.dhall

let proxmox_api_host = types.HostAddress.IP "192.178.11.101"

let config =
      { project_paths =
          project_paths
      , credentials =
          ./credentials.dhall
      , apis =
          [ types.API.Proxmox
            { proxmox_api_host =
                proxmox_api_host
            , proxmox_api_base_url =
                proxmoxAPIBaseURL proxmox_api_host
            , proxmox_api_url =
                proxmoxAPIURL proxmox_api_host
            }
          ]
        , gateway = "192.168.11.1"
      }

in config : types.Config
