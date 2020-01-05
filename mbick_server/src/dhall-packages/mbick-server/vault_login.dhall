let networking = ../networking/package.dhall
let HostURL/show = networking.HostURL.show

let config = ./config.dhall
let credentials = env:MBICK_SERVER_CREDENTIALS_FILE

in {
, address = HostURL/show config.vault_api.address
, method = "userpass"
, method_kv = {
    , username = credentials.vault_username
    }
}
