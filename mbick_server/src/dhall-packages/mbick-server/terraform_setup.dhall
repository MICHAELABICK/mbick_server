let networking = ../networking/package.dhall

let config = ./config.dhall
let credentials = env:MBICK_SERVER_CREDENTIALS_FILE


let showHostAddress =
      \(addr : networking.types.HostAddress)
  ->  merge
      {
      , Host = \(x : Text) -> x
      , IP = \(x : Text) -> x
      }
      addr

let vault_login_command =
      "VAULT_ADDR=${showHostAddress config.vault_address} "
      ++ "vault login "
      ++ "-method=userpass "
      ++ "-username=${credentials.vault_username}"

in vault_login_command
