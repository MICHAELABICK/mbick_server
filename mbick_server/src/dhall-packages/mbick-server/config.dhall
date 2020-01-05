let types = ./types.dhall
let networking = ../networking/package.dhall


let toProxmoxAPIBaseURL =
      \(host : networking.HostAddress.Type)
  ->  let address =
        merge
        { Host = \(x : Text) -> x
        , IP = \(x : Text) -> x
        }
        host
      in "https://${address}:8006"

let toProxmoxAPIURL =
      \(host : networking.HostAddress.Type)
  ->  let base = toProxmoxAPIBaseURL host
      in "${base}/api2/json"

let toProxmoxAPI =
      \(host : networking.HostAddress.Type)
  ->  let base_url = toProxmoxAPIBaseURL host
      let url      = toProxmoxAPIURL host
      in  { host = host
          , base_url = base_url
          , url = url
          }


let config =
      { project_paths =
          ../../paths2.dhall
      , proxmox_api =
          toProxmoxAPI (networking.HostAddress.Type.IP "192.168.11.101")
      , gateway = "192.168.11.1"
      , vault_api = {
          , address = {
            , protocol = networking.Protocol.HTTP
            , host = networking.HostAddress.Type.IP "192.168.11.104"
            , port = Some 8200
            }
          }
      }

in config : types.Config
