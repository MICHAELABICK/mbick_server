let networking = ../networking/package.dhall
let HostURL/show = networking.HostURL.show

let config = ./config.dhall
let credentials = env:MBICK_SERVER_CREDENTIALS_FILE

in {
, login =
    "vault login "
    ++ "-address=${HostURL/show config.vault_api.address} "
    ++ "-method=userpass "
    ++ "username=${credentials.vault_username}"
}
