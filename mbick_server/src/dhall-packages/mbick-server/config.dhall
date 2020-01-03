let types = ./types.dhall
let networking = ../networking/package.dhall


let toProxmoxAPIBaseURL =
      \(host : networking.types.HostAddress)
  ->  let address =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006"

let toProxmoxAPIURL =
      \(host : networking.types.HostAddress)
  ->  let base = toProxmoxAPIBaseURL host
      in "${base}/api2/json"

let toProxmoxAPI =
      \(host : networking.types.HostAddress)
  ->  let base_url = toProxmoxAPIBaseURL host
      let url      = toProxmoxAPIURL host
      in  { host = host
          , base_url = base_url
          , url = url
          }


let config =
      { project_paths =
          ../../paths2.dhall
      , credentials =
          ./credentials.dhall
      , proxmox_api =
          toProxmoxAPI (networking.types.HostAddress.IP "192.168.11.101")
      , gateway = "192.168.11.1"
      }

in config : types.Config
