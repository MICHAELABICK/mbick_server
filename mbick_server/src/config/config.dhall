let types = ./types.dhall


let toProxmoxAPIBaseURL =
      \(host : types.HostAddress)
  ->  let address =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006" : types.ProxmoxAPIBaseURL

let toProxmoxAPIURL =
      \(host : types.HostAddress)
  ->  let base = toProxmoxAPIBaseURL host
      in "${base}/api2/json" : types.ProxmoxAPIURL

let toProxmoxAPI =
      \(host : types.HostAddress)
  ->  let base_url = toProxmoxAPIBaseURL host
      let url      = toProxmoxAPIURL host
      in  { host = host
          , base_url = base_url
          , url = url
          } : types.ProxmoxAPI


let config =
      { project_paths =
          ../paths.dhall
      , credentials =
          ./credentials.dhall
      , proxmox_api =
          let host = types.HostAddress.IP "192.168.11.101"
          in toProxmoxAPI host
      , gateway = "192.168.11.1"
      }

in config : types.Config
