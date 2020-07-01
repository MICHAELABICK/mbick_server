let Prelude = ./Prelude.dhall
let Location = Prelude.Location.Type

let terraform = ../terraform/package.dhall
let mbick-server-types = ../mbick-server-types/package.dhall
let networking = ../networking/package.dhall

let HostURL = networking.HostURL
let HostURL/show = networking.HostURL.show
let HostAddress = networking.HostAddress
let Protocol = networking.Protocol

let types = ./types.dhall
let lab_config = ./config.dhall


let terraform_backend =
      terraform.types.Backend.S3 {
      , bucket = "mbick-server.terraform-state"
      , region = "us-west-1"
      , dynamodb_table = "terraform-lock"
      }

let ubuntuTemplate : mbick-server-types.ProxmoxVMTemplate = {
      , name = "ubuntu-bionic-1591581438"
      , groups = [ "ubuntu_bionic" ]
      }

let largeVM =
      \(name : Text)
  ->  \(ip : networking.IPAddress)
  ->  mbick-server-types.ProxmoxVM::
      { name = name
      -- , desc = "I don't think this works yet"
      , template = ubuntuTemplate
      , target_node = "node1"
      , cores = 4
      , sockets = 2
      , memory = 16384
      , disk_gb = 20
      , ip = ip
      , subnet = lab_config.subnet
      , gateway = lab_config.gateway
      }

let toTerraform =
      \(terraform_config : terraform.types.Config.Type)
  ->  terraform.toTerraform terraform_config lab_config


let docker01 =
      largeVM "docker01" "192.168.11.200" // {
      , groups = [ "docker_host" ]
      , disk_gb = 100
      }
    
let docker_config =
      terraform.types.Config::{
      , name = "docker_dev"
      , backend = terraform_backend
      , vms = [
          , docker01
          ]
      }

in {
, docker_dev =
    toTerraform docker_config
, services_dev =
    toTerraform
    terraform.types.Config::{
    , name = "services_dev"
    , backend = terraform_backend
    , remote_state = [
        , terraform.toTerraformRemoteState docker_config
        ]
    , docker_compose_files = [
        , {
          , name = "media_server"
          , file_path = ./. as Location
          , host_address =
              HostURL::{
              , protocol = Protocol.TCP
              , host = HostAddress.Type.IP "192.168.11.200"
              , port = Some 2375
              }
          }
        ]
    }
}
