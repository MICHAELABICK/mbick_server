let Prelude = ./Prelude.dhall
let Text/concatMap = Prelude.Text.concatMap
let Map = Prelude.Map.Type
let Entry = Prelude.Map.Entry
let List/map = Prelude.List.map
let List/concatMap = Prelude.List.concatMap
let List/null = Prelude.List.null
let Location = Prelude.Location.Type
let JSON = Prelude.JSON

let mbick-server-types = ../mbick-server-types/package.dhall
let networking = ../networking/package.dhall

let ProxmoxVM = mbick-server-types.ProxmoxVM
let DockerComposeFile = mbick-server-types.DockerComposeFile
let HostURL = networking.HostURL
let HostURL/show = networking.HostURL.show
let HostAddress = networking.HostAddress
let Protocol = networking.Protocol

let types = ./types.dhall
let toTerraformRemoteState = ./toTerraformRemoteState.dhall


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
  ->  \(lab_config : mbick-server-types.Config)
  ->  let playbook_dir =
            renderAbsolutePath lab_config.project_paths.ansible.playbooks
      in "${playbook_dir}/${playbook}"


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
      , content : Text
      , filename : Text
      }

let JSONProxmoxVM = {
      , name : Text
      , lifecycle : {
          , ignore_changes :
              List Text
          }
      , desc : Text
      , target_node : Text
      , clone : Text
      , full_clone : Bool
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
      , Type = {
          , depends_on : List Text
          , triggers : Map Text Text
          , provisioner : List JSONProvisioner
          }
      , default = {
          , depends_on = [] : List Text
          , triggers = [] : Map Text Text
          , provisioner = [] : List JSONProvisioner
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

let JSONResourceGroup = {
      , Type = {
          , proxmox_vm_qemu :
              Map Text JSONProxmoxVM
          , local_file :
              Map Text JSONLocalFile
          , null_resource :
              Map Text JSONNullResource.Type
          }
      , default = {
          , proxmox_vm_qemu =
              [] : Map Text JSONProxmoxVM
          , local_file =
              [] : Map Text JSONLocalFile
          , null_resource =
              [] : Map Text JSONNullResource.Type
          }
      }


let default_ansible_groups = [
      , "proxmox_vm"
      , "cloud_init"
      , "terraform_managed"
      ]

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

let toProxmoxVMResourceGroup =
      \(vm : ProxmoxVM.Type)
  ->  \(lab_config : mbick-server-types.Config)
  ->  let local_file_key = "${vm.name}_inventory_file"
      let ansible_playbook_command =
            "ansible-playbook "
            ++ "-i \"${renderAbsolutePath lab_config.project_paths.ansible.inventory}/group_inventory\" "
      in
      JSONResourceGroup::{
      , proxmox_vm_qemu = [
          , { mapKey = vm.name
            , mapValue = {
                , name = vm.name
                , lifecycle = {
                    -- Needed to fix the issues that could be solved by
                    -- https://github.com/Telmate/terraform-provider-proxmox/pull/152
                    , ignore_changes = [ "network" ]
                    }
                , connection = [
                    , { type = "ssh"
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
                , full_clone = True
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
                    ++ "gw=${lab_config.gateway}"
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
                              ++ "-i \"\${local_file.${local_file_key}.filename}\" "
                              ++ "-e \"ansible_user=\${data.vault_generic_secret.default_user.data[\"username\"]}\" "
                              ++ "\"${renderAnsiblePlaybookPath "provision.yml" lab_config}\""
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
                    ] : List JSONProvisioner
                }
            }
          ]
      , local_file = [
          , { mapKey = local_file_key
            , mapValue = {
                , content =
                    hostInventoryContent
                    vm
                    ( default_ansible_groups
                      # vm.groups
                    )
                , filename = "\${path.module}/files/${vm.name}_inventory"
                }
            }
          ]
      }

let toDockerComposeResourceGroup =
      \(file : DockerComposeFile)
  ->  \(lab_config : mbick-server-types.Config)
  ->  let depends_on =
           merge {
           , ProxmoxVM =
               \(x : mbick-server-types.ProxmoxVM.Type)
           ->  [ "proxmox_vm_qemu.${x.name}" ]
           }
           file.host
      let host_url =
            merge {
            , ProxmoxVM =
                \(x : mbick-server-types.ProxmoxVM.Type)
            ->  networking.HostURL::{
                , protocol = networking.Protocol.TCP
                , host = networking.HostAddress.Type.IP x.ip
                , port = Some 2375
                }
            }
            file.host
      let vault_address = HostURL/show lab_config.vault_api.address
      let vault_token_command =
            "vault token create "
            ++ "-address=${vault_address} "
            ++ "-display-name=docker_compose "
            ++ "-ttl=15m "
            ++ "-explicit-max-ttl=15m "
            ++ "-field=token"
      in
      JSONResourceGroup::{
      , null_resource = [
          , { mapKey = file.name
            , mapValue =
                JSONNullResource::{
                , depends_on = depends_on
                , triggers = [
                    , { mapKey = "timestamp", mapValue = "\${timestamp()}" }
                    ]
                , provisioner = [
                    , JSONProvisioner.LocalExec {
                        , local-exec = {
                            , command =
                                "docker-compose "
                                ++ "-f ${renderAbsolutePath file.file_path} "
                                ++ "build "
                                ++ "--parallel"
                            , environment =
                               Some
                               ( toMap {
                                 , DOCKER_HOST = HostURL/show host_url
                                 , COMPOSE_DOCKER_CLI_BUILD = "1"
                                 , DOCKER_BUILDKIT = "1"
                                 }
                               )
                            , when = None Text
                            , interpreter = None (List Text)
                            }
                        }
                    , JSONProvisioner.LocalExec {
                        , local-exec = {
                            , command =
                                "VAULT_TOKEN=$(${vault_token_command}) "
                                ++ "docker-compose "
                                ++ "-f ${renderAbsolutePath file.file_path} "
                                ++ "up "
                                ++ "--remove-orphans "
                                ++ "-d"
                            , environment =
                                Some
                                ( toMap {
                                  , DOCKER_HOST = HostURL/show host_url
                                  , VAULT_ADDR = vault_address
                                  }
                                )
                            , when = None Text
                            , interpreter = None (List Text)
                            }
                        }
                    ]
                }
            }
          ]
      }

let toBackend =
      \(terraform_config : types.Config.Type)
  ->  let remote_state = toTerraformRemoteState terraform_config
      let backend =
            merge {
            , S3 =
                \(x : types.S3RemoteState)
            ->  {
                , s3 = {
                    , bucket = x.backend.bucket
                    , key = x.key
                    , region = x.backend.region
                    , dynamodb_table = x.backend.dynamodb_table
                    , encrypt = True
                    }
                }
            }
            remote_state
      in backend

let toRemoteStateData =
      \(remote_state : types.RemoteState)
  ->  let name =
            merge {
            , S3 = \(x : types.S3RemoteState) -> x.name
            }
            remote_state
      let data_config =
            merge
            { S3 =
                \(x : types.S3RemoteState)
            ->  JSONRemoteStateData.s3 {
                , bucket = x.backend.bucket
                , key = x.key
                , region = x.backend.region
                }
            }
            remote_state
      in {
      , mapKey = name
      , mapValue =
          JSON.tagNested
          "config"
          "backend"
          JSONRemoteStateData
          data_config
      } : Entry Text (JSON.Tagged JSONRemoteStateData)

let foldJSONResourceGroups =
      \(x : JSONResourceGroup.Type)
  ->  \(y : JSONResourceGroup.Type)
  ->  {
      , proxmox_vm_qemu =
          x.proxmox_vm_qemu # y.proxmox_vm_qemu
      , local_file =
          x.local_file # y.local_file
      , null_resource =
          x.null_resource # y.null_resource
      } : JSONResourceGroup.Type

let toTerraform =
      \(terraform_config : types.Config.Type)
  ->  \(lab_config : mbick-server-types.Config)
  ->  let toLabProxmoxVMResourceGroup =
            \(vm : ProxmoxVM.Type) -> toProxmoxVMResourceGroup vm lab_config
      let toLabDockerComposeResourceGroup =
            \(file : DockerComposeFile) -> toDockerComposeResourceGroup file lab_config
      in {
      , terraform = {
          , backend = toBackend terraform_config
          }
      , provider = {
          , vault = { address = HostURL/show lab_config.vault_api.address }
          , proxmox = {
              , pm_tls_insecure = True
              , pm_api_url = HostURL/show lab_config.proxmox_api.address
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
              then None (List JSONVaultGenericSecretData)
              else
              Some
              ( toMap {
                , proxmox_user = { path = "proxmox_user/terraform" }
                , default_user = { path = "secret/default_user" }
                }
              )
          , vault_aws_access_credentials = {
              , terraform = {
                  , backend = "aws"
                  , role = "terraform"
                  }
              }
          , terraform_remote_state =
              if (List/null types.RemoteState terraform_config.remote_state)
              then None (Map Text (JSON.Tagged JSONRemoteStateData))
              else
              Some
              ( List/map
                types.RemoteState
                (Entry Text (JSON.Tagged JSONRemoteStateData))
                toRemoteStateData
                terraform_config.remote_state
              )
          }
      , resource =
          List/fold
          JSONResourceGroup.Type
          (
            ( List/map
              ProxmoxVM.Type
              JSONResourceGroup.Type
              toLabProxmoxVMResourceGroup
              terraform_config.vms
            )
            #
            ( List/map
              DockerComposeFile
              JSONResourceGroup.Type
              toLabDockerComposeResourceGroup
              terraform_config.docker_compose_files
            )
          )
          JSONResourceGroup.Type
          foldJSONResourceGroups
          JSONResourceGroup.default
          : JSONResourceGroup.Type
      , output = None (Map Text JSONOutput.Type)
      }


in toTerraform
