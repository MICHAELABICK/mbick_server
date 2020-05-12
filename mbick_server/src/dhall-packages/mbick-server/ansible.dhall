let networking = ../networking/package.dhall
let HostURL/show = networking.HostURL.show

let config = ./config.dhall

in {
, ssh_user_ca_public_key_endpoint =
    HostURL/show
    ( config.vault_api.address
      // { endpoint = Some "v1/ssh/public_key" }
    )
}
