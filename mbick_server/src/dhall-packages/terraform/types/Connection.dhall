let networking = ../networking.dhall

in
< ssh :
  { user : networking.types.SSHUser
  , private_key : Text
  , host : networking.types.HostAddress
  }
| none
>
