let networking = ../../networking/types.dhall

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
        networking.IPAddress
    , subnet :
        networking.Subnet
    , gateway :
        networking.Gateway
    }
, default = {
    , cores = 2
    , sockets = 1
    , agent = True
    }
}
