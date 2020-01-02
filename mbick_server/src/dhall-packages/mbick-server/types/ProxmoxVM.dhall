let networking = ../../networking/package.dhall

in
{ Type =
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
    , disk_gb :
        Natural
    , ip :
        networking.types.IPAddress
    , subnet :
        networking.types.Subnet
    , gateway :
        networking.types.Gateway
    }
, default = {
    , cores = 2
    , sockets = 1
    , agent = True
    }
}
