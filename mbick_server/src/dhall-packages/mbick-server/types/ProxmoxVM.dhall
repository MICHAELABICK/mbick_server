let networking = ../../networking/types.dhall

in
{ Type =
    { name :
        Text
    , groups :
        List Text
    , target_node :
        Text
    , template :
        ./ProxmoxVMTemplate.dhall
    , cores :
        Natural
    , sockets :
        Natural
    , memory :
        Natural
    , agent :
        Bool
    , disk_gb :
        Natural
    , ip :
        networking.IPAddress
    , subnet :
        networking.Subnet
    , gateway :
        networking.Gateway
    }
, default = {
    , groups = [] : List Text
    , cores = 1
    , sockets = 1
    , agent = True
    }
}
