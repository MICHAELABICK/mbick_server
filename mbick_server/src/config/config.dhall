let types = ./types.dhall


let makeProxmoxAPIBaseURL : types.HostAddress -> types.ProxmoxAPIBaseURL =
      \(host : types.HostAddress)
  ->  let address =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006"

let makeProxmoxAPIURL : types.HostAddress -> types.ProxmoxAPIURL =
      \(host : types.HostAddress)
  ->  let base = makeProxmoxAPIBaseURL host in "${base}/api2/json"


let project_paths = ../paths.dhall

let proxmox_api_host = types.HostAddress.IP "192.178.11.101"

let config =
      { project_paths =
          project_paths
      , credentials =
          ./credentials.dhall
      , apis =
          [ types.API.Proxmox
            { host =
                proxmox_api_host
            , base_url =
                makeProxmoxAPIBaseURL proxmox_api_host
            , url =
                makeProxmoxAPIURL proxmox_api_host
            }
          ]
        , gateway = "192.168.11.1"
      }

in config : types.Config
