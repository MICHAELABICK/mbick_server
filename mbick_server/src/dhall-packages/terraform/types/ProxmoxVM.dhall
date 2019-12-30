let networking = ../networking.dhall

in
{ name :
    Text
, desc :
    Text
, target_node :
    Text
, clone :
    Text
, cores :
    Natural
, sockets :
    Natural
, memory :
    Natural
, agent :
    Bool
, disks :
    List ./ProxmoxDisk.dhall
, networks :
    List ./ProxmoxNetworkDevice.dhall
, os_type :
    ./ProxmoxOSType.dhall
, ip :
    networking.types.IPAddress
, subnet :
    networking.types.Subnet
, gateway :
    networking.types.Gateway
, provisioners :
    List ./Provisioner.dhall
}
