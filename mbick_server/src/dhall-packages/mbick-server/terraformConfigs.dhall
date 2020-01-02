let Prelude = ./Prelude.dhall
let Map = Prelude.Map.Type
let List/map = Prelude.List.map

let ssh_user = "default-user"
let ssh_host = "7.7.7.7"
let ansible_dir = "ANSIBLE_DIR"
let ansible_playbook_command =
  "ansible-playbook "
  ++ "--private-key=PRIVATE_KEY "
  ++ "-i \"INVENTORY_FILE\" "

let types = ./types.dhall


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
              ++ "gw=GATEWAY"
          , ciuser = "TODO"
          , sshkeys = "TODO"
          , provisioner =
              [ JSONProvisioner.LocalExec
                { local-exec =
                    { command = "ssh-keygen -R ${ssh_host}"
                    , environment = [] : Map Text Text
                    , when = None Text
                    }
                }
              , JSONProvisioner.LocalExec
                { local-exec =
                    { command =
                        ansible_playbook_command
                        ++ "--limit \"${vm.name}\" "
                        ++ "-e \"ansible_user=${ssh_user}\" "
                        ++ " \"${ansible_dir}/manage_users.yml\""
                    , environment =
                        toMap { ANSIBLE_HOST_KEY_CHECKING = "false" }
                    , when = None Text
                    }
                }
              , JSONProvisioner.LocalExec
                { local-exec =
                    { command =
                        ansible_playbook_command
                        ++ "--limit \"${vm.name}\" "
                        ++ " \"${ansible_dir}/provision.yml\""
                    , environment = [] : Map Text Text
                    , when = None Text
                    }
                }
              , JSONProvisioner.LocalExec
                { local-exec =
                    { command = "ssh-keygen -R ${ssh_host}"
                    , environment = [] : Map Text Text
                    , when = Some "destroy"
                    }
                }
              ]
          }
      }
      : JSONProxmoxVM

let toTerraform =
      \(vms : List types.ProxmoxVM.Type)
  ->  { provider =
          { pm_tls_insecure = True
          , pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
          , pm_password = "secret"
          , pm_user = "terraform-user@pve"
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
      , ip = "192.168.11.120"
      , subnet =
          { ip = "192.168.11.0"
          , mask = 24
          }
      , gateway = "192.168.11.1"
      }


in {
, kube_dev =
    toTerraform [
    , test_resource
    -- , test_resource // { name = "kube-dev02" }
    ]
}
