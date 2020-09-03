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
        , name = "backups"
        , file_path =
            renderDockerComposeFilePath "backups/docker-compose.yml"
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


let gkeCluster =
      \(name : Text)
  ->  let project_id = "mbick-lab"
      let region = "us-east4"
      let zone = "us-east4-a"
      let location = zone
      let subnet = "10.10.0.0/24"
      let labels = { env = project_id }
      let tags = [ "terraform-managed" ]
      let tailscale_userdata_path =
            renderPath (./files/tailscale/userdata as Location)
      in
      {
      , provider = {
          , vault =
              { address = networking.HostURL.show lab_config.vault_api.address }
          , google = {
              , project = project_id
              }
          }
      , data = {
          , local_file = {
              , tailscale_userdata = {
                  , filename = tailscale_userdata_path
                  }
              }
          , vault_generic_secret =
              toMap {
              , tailscale = { path = "secret/tailscale" }
              }
          }
      , resource = {
          , google_compute_network = {
              , net = {
                  , name = "${project_id}-net"
                  , auto_create_subnetworks = False
                  }
              }
          , google_compute_subnetwork = {
              , subnet = {
                  , name = "${project_id}-subnet"
                  , region = region
                  , network = "\${google_compute_network.net.id}"
                  , ip_cidr_range = subnet
                  }
              }
          -- , google_compute_router = {
          --     , router = {
          --         , name = "${project_id}-router"
          --         , region = region
          --         , network = "\${google_compute_network.net.id}"
          --         }
          --     }
          -- , google_compute_router_nat = {
          --     , nat = {
          --         , name = "${project_id}-nat"
          --         , router = "\${google_compute_router.router.name}"
          --         , region = region
          --         , nat_ip_allocate_option = "AUTO_ONLY"
          --         , source_subnetwork_ip_ranges_to_nat =
          --             "ALL_SUBNETWORKS_ALL_IP_RANGES"
          --         }
          --     }
          , google_compute_instance = [
              , { mapKey = name
                , mapValue = {
                    , name = "${project_id}-tailscale-relay"
                    , machine_type = "f1-micro"
                    , zone = zone

                    , labels = labels
                    , tags = tags

                    , boot_disk = {
                        , auto_delete = True
                        , initialize_params = {
                            , image = "ubuntu-os-cloud/ubuntu-2004-lts"
                            }
                        }
                    , network_interface = {
                        , network =
                            "\${google_compute_network.net.id}"
                        , subnetwork =
                            "\${google_compute_subnetwork.subnet.name}"
                        , access_config = {
                            , network_tier = "STANDARD"
                            }
                        }
                    , scheduling = {
                        , preemptible = False
                        , on_host_maintenance = "MIGRATE"
                        }

                    , metadata_startup_script =
                        "\${data.local_file.tailscale_userdata.content}"
                    , metadata =
                        toMap {
                        , tailscale_auth_key =
                            "\${data.vault_generic_secret.tailscale.data[\"auth_key\"]}"
                        , tailscale_advertise_routes = subnet
                        }
                    , can_ip_forward = True
                    }
                }
              ]
          , google_container_cluster = [
              , { mapKey = name
                , mapValue = {
                    , name = name
                    , location = location
                    , remove_default_node_pool = True
                    , initial_node_count = 1
                    , network =
                        "\${google_compute_network.net.id}"
                    , subnetwork =
                        "\${google_compute_subnetwork.subnet.name}"
                    , master_auth = {
                        , username = ""
                        , password = ""
                        , client_certificate_config = {
                            , issue_client_certificate = False
                            }
                        }
                    }
                }
              ]
          , google_container_node_pool = [
              , { mapKey = "${name}_nodes"
                , mapValue = {
                    , name =
                        "\${google_container_cluster.primary.name}-node-pool"
                    , location = location
                    , cluster = name
                    , node_count = 1
                    , node_config = {
                        , oauth_scopes = [
                            , "https://www.googleapis.com/auth/logging.write"
                            , "https://www.googleapis.com/auth/monitoring"
                            ]
                        , metadata = {
                            , disable_legacy_endpoints = True
                            }
                        -- , preemptible = True
                        , preemptible = False
                        , machine_type = "e2-micro"

                        -- , disk_size_gb = 25
                        , disk_type = "pd-standard"

                        , labels =
                            labels // {
                            , vault_in_k8s = True -- for Hashicorp Vault
                            }
                        , tags = tags
                        }
                    }
                }  
              ]
          }
      , output = {
          , kubernetes_cluster_name = {
              , value = name
              , description = "GKE Cluster Name"
              }
          }
      }


in {
, docker_dev =
    toTerraform docker_config
, gke_dev =
    gkeCluster "primary"
}
