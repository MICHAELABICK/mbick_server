let Networking = ../../networking/types.dhall

in
{ name : Text
, desc : Text
, target_node : Text
, clone : Text
, cores : Natural
, sockets : Natural
, memory : Natural
, agent = ./QemuAgent.dhall
, disk =
    { id = Natural
    , type = ./ProxmoxDiskType.dhall
    , size = Natural
    , storage = Text
    }
, network =
    { id = Natural
    , model = ./ProxmoxNetworkModel.dhall
    , bridge = Text
    }
, os_type = "cloud-init"
, ip = Networking.IPAddress
, subnet = Networking.Subnet
, gateway = Networking.Gateway
}
