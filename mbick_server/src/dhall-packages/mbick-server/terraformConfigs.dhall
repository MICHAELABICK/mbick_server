let Prelude = ./Prelude.dhall
let Text/concatMap = Prelude.Text.concatMap
let Map = Prelude.Map.Type
let Entry = Prelude.Map.Entry
let List/map = Prelude.List.map
let List/concatMap = Prelude.List.concatMap
let List/null = Prelude.List.null
let Location = Prelude.Location.Type
let JSON = Prelude.JSON

let types = ./types.dhall
let config = ./config.dhall

let ProxmoxVM = types.ProxmoxVM
let DockerComposeFile = types.DockerComposeFile

let networking = ../networking/package.dhall
let HostURL = networking.HostURL
let HostURL/show = networking.HostURL.show
let HostAddress = networking.HostAddress
let Protocol = ../networking/types/Protocol.dhall

let renderAbsolutePath =
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

let renderAnsiblePlaybookPath =
      \(playbook : Text)
  ->  let playbook_dir =
            renderAbsolutePath config.project_paths.ansible.playbooks
      in "${playbook_dir}/${playbook}"

let ansible_playbook_command =
  "ansible-playbook "
  ++ "-i \"${renderAbsolutePath config.project_paths.ansible.inventory}/group_inventory\" "


let JSONProxmoxDisk =
      { id : Natural
      , type : Text
      , size : Natural
      , storage : Text
      , format : Text
      }

let JSONProxmoxDevice =
      { id : Natural
      , model : Text
      , bridge : Text
      }

let JSONConnection =
      { type : Text
      , user : Text
      , private_key : Text
      , host : Text
      }

let JSONLocalExecProvisioner = {
     , Type = {
         , local-exec : {
             , command : Text
             , environment : Optional (Map Text Text)
             , when : Optional Text
             , interpreter : Optional (List Text)
             }
         }
     , default = {
         , local-exec = {
             , environment = None (Map Text Text)
             , when = None Text
             , interpreter = None (List Text)
             }
         }
     }

let JSONProvisioner =
      < LocalExec :
         JSONLocalExecProvisioner.Type
      | RemoteExec :
          { remote-exec :
              { inline : List Text
              }
          }
      >

let JSONLocalFile = {
      , mapKey : Text
      , mapValue : {
          , content : Text
          , filename : Text
          }
      }

let JSONProxmoxVM =
      { mapKey : Text
      , mapValue :
          { name : Text
          , desc : Text
          , target_node : Text
          , clone : Text
          -- TODO: this needs to be updated when the terraform provider gets updated
          -- , full_clone : Bool
          , cores : Natural
          , sockets : Natural
          , numa : Bool
          , memory : Natural
          , agent : Natural
          , disk : List JSONProxmoxDisk
          , network : List JSONProxmoxDevice
          , os_type : Text
          , ipconfig0 : Text
          , connection : List JSONConnection
          , ciuser : Text
          , sshkeys : Text
          , provisioner : List JSONProvisioner
          }
      }

let JSONRemoteStateData =
      < s3 : {
          , bucket : Text
          , key : Text
          , region : Text
          }
      >

let JSONVaultGenericSecretData = {
      , mapKey : Text
      , mapValue : {
          , path : Text
          }
      }

let JSONNullResource = {
      , mapKey : Text
      , mapValue : {
          , triggers : Map Text Text
          , provisioner : List JSONProvisioner
          }
      }

let JSONOutput = {
      , Type = {
          , value : Text
          , description : Optional Text
          , sensitive : Bool
          }
      , default = {
          , description = None Text
          , sensitive = False
          }
      }


let TerraformBackend = {
      , bucket : Text
      , region : Text
      , dynamodb_table : Text
      }

let TerraformRemoteState = {
      , name : Text
      , backend : TerraformBackend
      , key : Text
      }

let TerraformConfig = {
      , Type = {
          , name : Text
          , backend : TerraformBackend
          , remote_state : List TerraformRemoteState
          , vms : List ProxmoxVM.Type
          , docker_compose_files : List DockerComposeFile
          }
      , default = {
          , remote_state = [] : List TerraformRemoteState
          , vms = [] : List ProxmoxVM.Type
          , docker_compose_files = [] : List DockerComposeFile
          }
      }

let default_ansible_groups = [
      , "proxmox_vm"
      , "cloud_init"
      , "terraform_managed"
      ]

let localFileName =
      \(vm : ProxmoxVM.Type)
  ->  "${vm.name}_inventory_file"

let hostInventoryContent =
      \(vm : ProxmoxVM.Type)
  ->  \(groups : List Text)
  ->  let group_definitions =
            Text/concatMap
            Text
            ( \(group : Text) ->
              ''

              [${group}]
              ${vm.name}
              ''
            )
            groups
      in
      ''
      [all]
      ${vm.name} ansible_host=${vm.ip}
      ''
      ++ group_definitions

let toQemuAgentEnable =
      \(enable : Bool)
  ->  if enable then 1 else 0 : Natural

let toLocalFileResource =
      \(vm : ProxmoxVM.Type)
  ->  { mapKey = localFileName vm
      , mapValue = {
          , content =
              hostInventoryContent
              vm
              ( default_ansible_groups
                # vm.groups
              )
          , filename = "\${path.module}/files/${vm.name}_inventory"
          }
      } : JSONLocalFile

let toProxmoxVMResource =
      \(vm : ProxmoxVM.Type)
  ->  { mapKey = vm.name
      , mapValue = {
          , name = vm.name
          , connection =
              [ { type = "ssh"
                , user =
                    "\${data.vault_generic_secret.default_user.data[\"username\"]}"
                , private_key =
                    "\${data.vault_generic_secret.default_user.data[\"private_key\"]}"
                , host = vm.ip
                }
              ]
          , desc =
              JSON.render
              ( JSON.object
                [ { mapKey = "groups"
                  , mapValue =
                      JSON.array
                      ( List/map
                        Text
                        JSON.Type
                        JSON.string
                        ( [ "proxmox_vm"
                          , "cloud_init"
                          , "terraform_managed"
                          ]
                          # vm.template.groups
                          # vm.groups
                        )
                      )
                  }
                ]
              )
          , target_node = vm.target_node
          , clone = vm.template.name
          -- , full_clone = True
          , cores = vm.cores
          , sockets = vm.sockets
          , numa = True
          , memory = vm.memory
          , agent = toQemuAgentEnable vm.agent
          , disk =
              [ { id = 0
                , type = "scsi"
                , size = vm.disk_gb
                , storage = "vm-images"
                , format = "qcow2"
                }
              ]
          , network =
              [ { id = 0
                , model = "virtio"
                , bridge = "vmbr0"
                }
              ]
          , os_type = "cloud-init"
          , ipconfig0 =
              "ip=${vm.ip}/${Natural/show vm.subnet.mask},"
              ++ "gw=${config.gateway}"
          , ciuser =
              "\${data.vault_generic_secret.default_user.data[\"username\"]}"
          , sshkeys =
              "\${data.vault_generic_secret.default_user.data[\"public_key\"]}"
              -- -- Was having problems with my Emacs syntax highlighting,
              -- -- but the following is a more useful version of the above
              -- ''
              -- ''${chomp(data.vault_generic_secret.default_user.data["public_key"])}
              -- ''
          , provisioner = [
              -- , JSONProvisioner.RemoteExec
              --   { remote-exec =
              --       { inline = [
              --           "ip a"
              --         ]
              --       }
              --   }
              , JSONProvisioner.RemoteExec
                { remote-exec =
                    { inline = [
                        "echo \"Connection to ${vm.ip} established\""
                      ]
                    }
                }
              , JSONProvisioner.LocalExec {
                , local-exec = {
                    , command =
                        ansible_playbook_command
                        ++ "-i \"\${local_file.${localFileName vm}.filename}\" "
                        ++ "-e \"ansible_user=\${data.vault_generic_secret.default_user.data[\"username\"]}\" "
                        ++ "\"${renderAnsiblePlaybookPath "provision.yml"}\""
                    , environment = None (Map Text Text)
                    -- , environment =
                    --     Some
                    --     ( toMap {
                    --       , PRIVATE_KEY =
                    --           "\${data.vault_generic_secret.default_user.data[\"private_key\"]}"
                    --       }
                    --     )
                    , when = None Text
                    , interpreter = None (List Text)
                    }
                }
              ]
          }
      }
      : JSONProxmoxVM

let toOutputs =
      \(vm : ProxmoxVM.Type)
  ->  [
      , { mapKey = "${vm.name}_address"
        , mapValue =
            JSONOutput::{
            , value = vm.ip
            }
        }
      ] : Map Text JSONOutput.Type

let toDockerComposeResource =
      \(file : DockerComposeFile)
  ->  {
      , mapKey = file.name
      , mapValue = {
          , triggers = [
              , { mapKey = "timestamp", mapValue = "\${timestamp()}" }
              ]
          , provisioner = [
              , JSONProvisioner.LocalExec {
                  , local-exec = {
                      , command = "docker-compose up -d ${renderAbsolutePath file.file_path}"
                      , environment = Some [
                          , { mapKey = "DOCKER_HOST"
                            , mapValue =
                                HostURL/show
                                file.host_address
                            }
                          ]
                      , when = None Text
                      , interpreter = None (List Text)
                      }
                  }
              ]
          }
      } : JSONNullResource

let toTerraformRemoteState =
      \(terraform_config : TerraformConfig.Type)
  ->  {
      , name = terraform_config.name
      , backend = terraform_config.backend
      , key = "${terraform_config.name}/terraform.tfstate"
      } : TerraformRemoteState

let toTerraformBackend =
      \(terraform_config : TerraformConfig.Type)
  ->  let remote_state = toTerraformRemoteState terraform_config
      in {
      , s3 = {
          , bucket = remote_state.backend.bucket
          , key = remote_state.key
          , region = remote_state.backend.region
          , dynamodb_table = remote_state.backend.dynamodb_table
          , encrypt = True
          }
      }

let toTerraformRemoteStateData =
      \(remote_state : TerraformRemoteState)
  ->  [
      , {
        , mapKey = remote_state.name
        , mapValue =
            JSON.tagNested
            "backend"
            "config"
            JSONRemoteStateData
            ( JSONRemoteStateData.s3 {
              , bucket = remote_state.backend.bucket
              , key = remote_state.key
              , region = remote_state.backend.region
              }
            )
        }
      ] : Map Text (JSON.Tagged JSONRemoteStateData)

let toTerraform =
      \(terraform_config : TerraformConfig.Type)
  ->  {
      , terraform = {
          , backend = toTerraformBackend terraform_config
          }
      , provider = {
          , vault = { address = HostURL/show config.vault_api.address }
          , proxmox = {
              , pm_tls_insecure = True
              , pm_api_url = HostURL/show config.proxmox_api.address
              , pm_password =
                  "\${data.vault_generic_secret.proxmox_user.data[\"password\"]}"
              , pm_user =
                  "\${data.vault_generic_secret.proxmox_user.data[\"username\"]}"
              }
          , aws = {
              , access_key = "\${data.vault_aws_access_credentials.terraform.access_key}"
              , secrety_key = "\${data.vault_aws_access_credentials.terraform.secret_key}"
              , region = "us-west-1"
              }
          }
      , data = {
          , vault_generic_secret =
              if (List/null ProxmoxVM.Type terraform_config.vms)
              then [] : List JSONVaultGenericSecretData
              else [
              , { mapKey = "proxmox_user"
                , mapValue = { path = "proxmox_user/terraform" }
                }
              , { mapKey = "default_user"
                , mapValue = { path = "secret/default_user" }
                }
              ]
          , vault_aws_access_credentials = {
              , terraform = {
                  , backend = "aws"
                  , role = "terraform"
                  }
              }
          , terraform_remote_state =
              List/concatMap
              TerraformRemoteState
              (Entry Text (JSON.Tagged JSONRemoteStateData))
              toTerraformRemoteStateData
              terraform_config.remote_state
          }
      , resource = {
          , proxmox_vm_qemu =
              List/map
              ProxmoxVM.Type
              JSONProxmoxVM
              toProxmoxVMResource
              terraform_config.vms
          , local_file =
              List/map
              ProxmoxVM.Type
              JSONLocalFile
              toLocalFileResource
              terraform_config.vms
          , null_resource =
              List/map
              DockerComposeFile
              JSONNullResource
              toDockerComposeResource
              terraform_config.docker_compose_files
          }
      , output =
          List/concatMap
          ProxmoxVM.Type
          (Entry Text JSONOutput.Type)
          toOutputs
          terraform_config.vms
      }


let terraform_backend : TerraformBackend = {
      , bucket = "mbick-server.terraform-state"
      , region = "us-west-1"
      , dynamodb_table = "terraform-lock"
      }

let ubuntuTemplate : types.ProxmoxVMTemplate = {
      , name = "ubuntu-bionic-1591581438"
      , groups = [ "ubuntu_bionic" ]
      }

let largeVM =
      \(name : Text)
  ->  \(ip : networking.IPAddress)
  ->  ProxmoxVM::
      { name = name
      -- , desc = "I don't think this works yet"
      , template = ubuntuTemplate
      , target_node = "node1"
      , cores = 4
      , sockets = 2
      , memory = 16384
      , disk_gb = 20
      , ip = ip
      , subnet = config.subnet
      , gateway = config.gateway
      }


let docker_config =
      TerraformConfig::{
      , name = "docker_dev"
      , backend = terraform_backend
      , vms = [
          , largeVM "docker01" "192.168.11.200" // {
              , groups = [ "docker_host" ]
              , disk_gb = 100
              }
          ]
      }

in {
, docker_dev =
    toTerraform docker_config
, services_dev =
    toTerraform
    TerraformConfig::{
    , name = "services_dev"
    , backend = terraform_backend
    , remote_state = [
        , toTerraformRemoteState docker_config
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
