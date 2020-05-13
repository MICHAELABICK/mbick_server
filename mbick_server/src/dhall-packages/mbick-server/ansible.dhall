let networking = ../networking/package.dhall
let HostURL/show = networking.HostURL.show

let config = ./config.dhall

in {
, vault_api_url =
    HostURL/show
    config.vault_api.address
, proxmox_api_url =
    HostURL/show
    ( config.proxmox_api.address
      // { endpoint = None Text }
    )
, ssh_user_ca_public_key_endpoint =
    HostURL/show
    ( config.vault_api.address
      // { endpoint = Some "v1/ssh/public_key" }
    )
}
