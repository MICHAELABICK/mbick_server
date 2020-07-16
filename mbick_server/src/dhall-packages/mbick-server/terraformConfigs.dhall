let Prelude = ./Prelude.dhall
let Location = Prelude.Location.Type

let mbick-server-terraform = ../mbick-server-terraform/package.dhall
let mbick-server-types = ../mbick-server-types/package.dhall
let networking = ../networking/package.dhall

let lab_config = ./config.dhall


let renderPath =
      \(loc : Location)
  ->  merge {
      , Local =
          \(x : Text) -> x
      , Remote =
          \(x : Text) -> ""
      , Environment =
          \(x : Text) -> ""
      , Missing = ""
      }
      loc

let renderDockerComposeFilePath =
      \(compose_file : Text)
  ->  let docker_dir =
            renderPath lab_config.project_paths.docker
      in Location.Local "${docker_dir}/${compose_file}"


let LabEnvironment = <
      | Prod
      | Dev
      >

let terraform_backend =
      mbick-server-terraform.types.Backend.S3 {
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
      \(terraform_config : mbick-server-terraform.types.Config.Type)
  ->  \(environment : LabEnvironment)
  ->  let name_suffix =
            merge {
            , Prod = "prod"
            , Dev = "dev"
            }
            environment
      let name = "${terraform_config.name}_${name_suffix}"
      in
      mbick-server-terraform.toTerraform
      ( terraform_config // {
        , name = name
        }
      )
      lab_config


let docker01 =
      largeVM "docker01" "192.168.11.200" // {
      , groups = [ "docker_host" ]
      , disk_gb = 100
      }
    
let docker_config =
      mbick-server-terraform.types.Config::{
      , name = "docker"
      , backend = terraform_backend
      , vms = [
          , docker01
          ]
      }

let services_config =
      mbick-server-terraform.types.Config::{
      , name = "services"
      , backend = terraform_backend
      , remote_state = [
          , mbick-server-terraform.toTerraformRemoteState docker_config
          ]
      , docker_compose_files = [
          , {
            , name = "admin_infra"
            , file_path =
                renderDockerComposeFilePath "admin_infra/docker-compose.yml"
            , host_address =
                networking.HostURL::{
                , protocol = networking.Protocol.TCP
                , host = networking.HostAddress.Type.IP "192.168.11.200"
                , port = Some 2375
                }
            }
          , {
            , name = "media_server"
            , file_path =
                renderDockerComposeFilePath "media_server/docker-compose.yml"
            , host_address =
                networking.HostURL::{
                , protocol = networking.Protocol.TCP
                , host = networking.HostAddress.Type.IP "192.168.11.200"
                , port = Some 2375
                }
            }
          , {
            , name = "syncthing"
            , file_path = renderDockerComposeFilePath "syncthing/docker-compose.yml"
            , host_address =
                networking.HostURL::{
                , protocol = networking.Protocol.TCP
                , host = networking.HostAddress.Type.IP "192.168.11.200"
                , port = Some 2375
                }
            }
          ]
      }

in {
, docker_prod =
    toTerraform docker_config LabEnvironment.Prod
, docker_dev =
    toTerraform docker_config LabEnvironment.Dev
, services_prod =
    toTerraform services_config LabEnvironment.Prod
, services_dev =
    toTerraform services_config LabEnvironment.Dev
}
