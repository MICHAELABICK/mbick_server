{ name : Text
, node : ./ProxmoxNode.dhall
, template : ./ProxmoxTemplate.dhall
, cores : Natural
, sockets : Natural
, memory : Natural
, disk_gb : Natural
, ip : ./IPAddress.dhall
}
