
let Prelude = ./Prelude.dhall
let types = ./types.dhall
let networking = ../networking/package.dhall

let Location = Prelude.Location.Type
let HostURL = networking.HostURL
let HostURL/show = HostURL.show

let config = ./config.dhall
let paths = config.project_paths


let showBaseURL =
      \(url : HostURL.Type)
  ->  let base_url = url // { endpoint = None Text }
      in HostURL/show base_url

let defaults = {
      , ansible_dir = paths.ansible.playbooks
      , ansible_inventory_dir = paths.ansible.inventory
      , proxmox_api_host =
          showBaseURL config.proxmox_api.address
      , proxmox_api_url =
          HostURL/show config.proxmox_api.address
      } :
      { ansible_dir : Location
      , ansible_inventory_dir : Location
      , proxmox_api_host : Text
      , proxmox_api_url : Text
      }


in {
, defaults = defaults
}
