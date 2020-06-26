let Prelude = ./Prelude.dhall
let Text/concatMap = Prelude.Text.concatMap
let Map = Prelude.Map.Type
let List/map = Prelude.List.map
let Location = Prelude.Location.Type
let JSON = Prelude.JSON

let types = ./types.dhall
let config = ./config.dhall

let ProxmoxVM = types.ProxmoxVM

let networking = ../networking/package.dhall
let HostURL/show = networking.HostURL.show

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

let toTerraform =
      \(vms : List ProxmoxVM.Type)
  ->  { provider = {
          , vault = { address = HostURL/show config.vault_api.address }
          , proxmox = {
              , pm_tls_insecure = True
              , pm_api_url = HostURL/show config.proxmox_api.address
              , pm_password =
                  "\${data.vault_generic_secret.proxmox_user.data[\"password\"]}"
              , pm_user =
                  "\${data.vault_generic_secret.proxmox_user.data[\"username\"]}"
              }
          }
      , data = {
          , vault_generic_secret = {
              , proxmox_user = { path = "proxmox_user/terraform" }
              , default_user = { path = "secret/default_user" }
              }
          }
      , resource = {
          , proxmox_vm_qemu =
              List/map
              ProxmoxVM.Type
              JSONProxmoxVM
              toProxmoxVMResource
              vms
          , local_file =
              List/map
              ProxmoxVM.Type
              JSONLocalFile
              toLocalFileResource
              vms
          }
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
      , memory = 8192
      , disk_gb = 20
      , ip = ip
      , subnet = config.subnet
      , gateway = config.gateway
      }


in {
, docker_dev =
    toTerraform [
    , largeVM "docker01" "192.168.11.200" // {
        , groups = [ "docker_host" ]
        , disk_gb = 100
        }
    ]
, kube_dev =
    toTerraform [
    , largeVM "kube01" "192.168.11.130" // { groups = [ "k3s_control_node" ] }
    ]
}
