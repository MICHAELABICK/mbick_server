let Hostname = Text
let IpAddress = Text

let SshUsername = Text
let SshUser =
  { username : SshUsername
  } : Type

let ProxmoxUsername = Text
let ProxmoxPassword = Text
let ProxmoxUser =
  { username : ProxmoxUsername
  , password : ProxmoxPassword
  } : Type
let ProxmoxApiUrl = Text
let ProxmoxApiBaseUrl = Text

in
{ HostAddress = < Host : Hostname | IP : IpAddress >
, Hostname = Hostname
, IpAddress = IpAddress
, SshUser = SshUser
, SshUsername = SshUsername
, ProxmoxUser = ProxmoxUser
, ProxmoxUsername = ProxmoxUsername
, ProxmoxPassword = ProxmoxPassword
, ProxmoxApiUrl = ProxmoxApiUrl
, ProxmoxApiBaseUrl = ProxmoxApiBaseUrl
}
