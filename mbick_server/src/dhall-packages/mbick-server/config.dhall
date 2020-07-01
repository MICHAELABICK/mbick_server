let mbick-server-types = ../mbick-server-types/package.dhall
let networking = ../networking/package.dhall


let config =
      { project_paths =
          ../../paths.dhall
      , proxmox_api =
          { address =
              networking.HostURL::{
              , protocol = networking.Protocol.HTTPS
              , host = networking.HostAddress.Type.IP "192.168.11.101"
              , port = Some 8006
              , endpoint = Some "api2/json"
              }
          }
      , gateway = "192.168.11.1"
      , subnet = {
          , ip = "192.168.11.0"
          , mask = 24
          }
      , vault_api = {
          , address =
              networking.HostURL::{
              , protocol = networking.Protocol.HTTP
              , host = networking.HostAddress.Type.IP "192.168.11.104"
              , port = Some 8200
              }
          }
      }

in config : mbick-server-types.Config
