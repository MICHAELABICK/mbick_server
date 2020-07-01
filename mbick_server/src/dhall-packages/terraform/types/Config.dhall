let mbick-server-types = ../../mbick-server-types/package.dhall

let Backend = ./Backend.dhall
let RemoteState = ./RemoteState.dhall

in {
, Type = {
    , name : Text
    , backend : Backend
    , remote_state : List RemoteState
    , vms : List mbick-server-types.ProxmoxVM.Type
    , docker_compose_files : List mbick-server-types.DockerComposeFile
    }
, default = {
    , remote_state = [] : List RemoteState
    , vms = [] : List mbick-server-types.ProxmoxVM.Type
    , docker_compose_files = [] : List mbick-server-types.DockerComposeFile
    }
}
