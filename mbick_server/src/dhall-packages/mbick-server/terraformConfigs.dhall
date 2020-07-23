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


let terraform_backend =
      mbick-server-terraform.types.Backend.S3 {
      , bucket = "mbick-server.terraform-state"
      , region = "us-west-1"
      , dynamodb_table = "terraform-lock"
      }

let ubuntuTemplate : mbick-server-types.ProxmoxVMTemplate = {
      , name = "ubuntu-bionic-1595014229"
      , groups = [ "ubuntu_bionic" ]
      }

let dockerTemplate : mbick-server-types.ProxmoxVMTemplate = {
      , name = "docker-1595012750"
      , groups = [
          , "ubuntu_bionic"
          , "docker_host"
          ]
      }

let smallVM =
      \(name : Text)
  ->  \(ip : networking.IPAddress)
  ->  mbick-server-types.ProxmoxVM::
      { name = name
      -- , desc = "I don't think this works yet"
      , template = ubuntuTemplate
      , target_node = "node1"
      , cores = 1
      , sockets = 1
      , memory = 1024
      , disk_gb = 25
      , ip = ip
      , subnet = lab_config.subnet
      , gateway = lab_config.gateway
      }
  
let largeVM =
      \(name : Text)
  ->  \(ip : networking.IPAddress)
  ->  ( smallVM
        name
        ip
      ) // {
      , cores = 4
      , sockets = 2
      , memory = 16384
      }

let toTerraform =
      \(terraform_config : mbick-server-terraform.types.Config.Type)
  ->  mbick-server-terraform.toTerraform terraform_config lab_config


let docker01 =
      largeVM "docker01" "192.168.11.200" // {
      , template = dockerTemplate
      , groups = [ "docker_host" ]
      , disk_gb = 100
      }

let pihole01 =
      smallVM "pihole01" "192.168.11.3" // {
      , template = dockerTemplate
      , groups = [ "docker_host" ]
      }

let docker_services = [
      , {
        , name = "admin_infra"
        , file_path =
            renderDockerComposeFilePath "admin_infra/docker-compose.yml"
        , host =
            mbick-server-types.DockerHost.ProxmoxVM docker01
        }
      , {
        , name = "media_server"
        , file_path =
            renderDockerComposeFilePath "media_server/docker-compose.yml"
        , host =
            mbick-server-types.DockerHost.ProxmoxVM docker01
        }
      , {
        , name = "syncthing"
        , file_path =
            renderDockerComposeFilePath "syncthing/docker-compose.yml"
        , host =
            mbick-server-types.DockerHost.ProxmoxVM docker01
        }
      , {
        , name = "pihole"
        , file_path =
            renderDockerComposeFilePath "pihole/docker-compose.yml"
        , host =
            mbick-server-types.DockerHost.ProxmoxVM pihole01
        }
      ]
    
let docker_config =
      mbick-server-terraform.types.Config::{
      , name = "docker_dev"
      , backend = terraform_backend
      , vms = [
          , docker01
          , pihole01
          ]
      , docker_compose_files = docker_services
      }

in {
, docker_dev =
    toTerraform docker_config
}
