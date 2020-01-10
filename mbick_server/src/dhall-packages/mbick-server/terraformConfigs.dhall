let Prelude = ./Prelude.dhall
let Map = Prelude.Map.Type
let List/map = Prelude.List.map
let Location = Prelude.Location.Type

let types = ./types.dhall
let config = ./config.dhall

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
  ++ "-i \"${renderAbsolutePath config.project_paths.ansible.inventory}\" "


let JSONProxmoxDisk =
      { id : Natural
      , type : Text
      , size : Natural
      , storage : Text
      }

let JSONProxmoxDevice =
      { id : Natural
      , model : Text
      , bridge : Text
      }

let JSONProvisioner =
      < LocalExec :
          { local-exec :
              { command : Text
              , environment : Map Text Text
              , when : Optional Text
              }
          }
      | RemoteExec :
          { remote-exec :
              { inline : List Text
              }
          }
      >

let JSONProxmoxVM =
      { mapKey : Text
      , mapValue :
          { name : Text
          , desc : Text
          , target_node : Text
          , clone : Text
          , cores : Natural
          , sockets : Natural
          , memory : Natural
          , agent : Natural
          , disk : List JSONProxmoxDisk
          , network : List JSONProxmoxDevice
          , os_type : Text
          , ipconfig0 : Text
          , ciuser : Text
          , sshkeys : Text
          , provisioner : List JSONProvisioner
          }
      }


let toQemuAgentEnable =
      \(enable : Bool)
  ->  if enable then 1 else 0 : Natural

let toResource =
      \(vm : types.ProxmoxVM.Type)
  ->  { mapKey = vm.name
      , mapValue =
          { name = vm.name
          , desc = vm.desc
          , target_node = vm.target_node
          , clone = vm.clone
          , cores = vm.cores
          , sockets = vm.sockets
          , memory = vm.memory
          , agent = toQemuAgentEnable vm.agent
          , disk =
              [ { id = 0
                , type = "scsi"
                , size = vm.disk_gb
                , storage = "local-zfs"
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
              ''
              ''${data.vault_generic_secret.default_user.data["public_key"]}
              ''
          , provisioner = [
              , JSONProvisioner.RemoteExec
                { remote-exec =
                    { inline = [ "ip a" ] }
                }
              -- , JSONProvisioner.LocalExec
              --   { local-exec =
              --       { command = "ssh-keygen -R ${vm.ip}"
              --       , environment = [] : Map Text Text
              --       , when = None Text
              --       }
              --   }
              -- , JSONProvisioner.LocalExec
              --   { local-exec =
              --       { command =
              --           ansible_playbook_command
              --           ++ "--limit \"${vm.name}\" "
              --           ++ "-e \"ansible_user=${default_user}\" "
              --           ++ "--private-key=PRIVATE_KEY "
              --           ++ "\"${renderAnsiblePlaybookPath "manage_users.yml"}\""
              --       , environment =
              --           toMap { ANSIBLE_HOST_KEY_CHECKING = "false" }
              --       , when = None Text
              --       }
              --   }
              -- , JSONProvisioner.LocalExec
              --   { local-exec =
              --       { command =
              --           ansible_playbook_command
              --           ++ "--limit \"${vm.name}\" "
              --           ++ "\"${renderAnsiblePlaybookPath "provision.yml"}\""
              --       , environment = [] : Map Text Text
              --       , when = None Text
              --       }
              --   }
              -- , JSONProvisioner.LocalExec
              --   { local-exec =
              --       { command = "ssh-keygen -R ${vm.ip}"
              --       , environment = [] : Map Text Text
              --       , when = Some "destroy"
              --       }
              --   }
              ]
          }
      }
      : JSONProxmoxVM

let toTerraform =
      \(vms : List types.ProxmoxVM.Type)
  ->  { provider = {
          , vault = { address = HostURL/show config.vault_api.address }
          , proxmox = {
              , pm_tls_insecure = True
              , pm_api_url = config.proxmox_api.url
              , pm_password =
                  "\${data.vault_generic_secret.proxmox_user.data[\"password\"]}"
              , pm_user = "vm-admin"
              }
          }
      , data = {
          , vault_generic_secret = {
              , proxmox_user = { path = "proxmox_user/vm-admin" }
              , default_user = { path = "secret/default_user" }
              }
          }
      , resource =
          { proxmox_vm_qemu =
              List/map
              types.ProxmoxVM.Type
              JSONProxmoxVM
              toResource
              vms
          }
      }


let test_resource =
      types.ProxmoxVM::
      { name = "kube-dev01"
      , desc = "I don't think this works yet"
      , target_node = "node1"
      , clone = "ubuntu-bionic-1570324283"
      , memory = 4096
      , disk_gb = 20
      , ip = "192.168.11.130"
      , subnet =
          { ip = "192.168.11.0"
          , mask = 24
          }
      , gateway = config.gateway
      }


in {
, kube_dev =
    toTerraform [
    , test_resource
    -- , test_resource // { name = "kube-dev02" }
    ]
}
