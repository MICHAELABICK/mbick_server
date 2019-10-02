let types = ./types.dhall


let makeProxmoxAPIBaseURL =
      \(host : types.HostAddress)
  ->  let address =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006" : types.ProxmoxAPIBaseURL

let makeProxmoxAPIURL =
      \(host : types.HostAddress)
  ->  let base = makeProxmoxAPIBaseURL host
      in "${base}/api2/json" : types.ProxmoxAPIURL

let makeProxmoxAPI =
      \(host : types.HostAddress)
  ->  let base_url = makeProxmoxAPIBaseURL host
      let url      = makeProxmoxAPIURL host
      in  { host = host
          , base_url = base_url
          , url = url
          } : types.ProxmoxAPI


let project_paths = ../paths.dhall

let proxmox_api_host = types.HostAddress.IP "192.178.11.101"

let config =
      { project_paths =
          project_paths
      , credentials =
          ./credentials.dhall
      , apis =
          [ makeProxmoxAPI proxmox_api_host
          ]
        , gateway = "192.168.11.1"
      }

in config : types.Config
