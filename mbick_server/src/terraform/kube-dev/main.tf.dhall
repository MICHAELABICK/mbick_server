let terraform = ../../dhall-packages/terraform/package.dhall

let Config = terraform.types.Config
let Resource = terraform.types.Resource

let Provisioner = terraform.types.Provisioner
let ProvisionerWhen = terraform.types.ProvisionerWhen
let EnvironmentVariable = terraform.types.EnvironmentVariable
let Connection = terraform.types.Connection

let ProxmoxDiskType = terraform.types.ProxmoxDiskType
let ProxmoxNetworkDeviceModel = terraform.types.ProxmoxNetworkDeviceModel

-- let deployment : types.TFDeployment =
--       { config = config
--       , resources =
--         [ types.ProxmoxVM
--           { name = "kube-dev01"
--           , node = "node1"
--           , template = "ubuntu-bionic-1570324283"
--           , cores = 2
--           , sockets = 1
--           , memory = 4096
--           , disk_gb = 20
--           , ip : "192.168.11.120"
--           , groups =
--               [ "ubuntu_bionic"
--               , "k3s_control_node"
--               ]
--           }
--         ]
--       }

-- in renderTFDeployment deployment

in
{ providers = []
, resources =
    [ Resource.ProxmoxVM
      { name = "kube-dev01"
      , desc = "I don't think this works yet"
      , taget_node = "node1"
      , clone = "ubuntu-bionic-1570324283"
      , cores = 2
      , sockets = 1
      , memory = 4096
      , agent = True
      , disks =
          [ { id = 0
            , type = ProxmoxDiskType.SCSI
            , size_gb = 20
            , storage = "local-zfs"
            }
          ]
      , network_devices =
          [ { id = 0
            , model = ProxmoxNetworkDeviceModel.VirtIO
            , bridge = "vmbr0"
            }
          ]
      , ip = "192.168.11.120"
      , subnet =
          { ip = "192.168.11.0"
          , mask = 24
          }
      , gateway = "192.168.11.1"
      , provisioners =
          [ Provisioner.LocalExec
            { command =
                "ssh-keygen -R ${local.ssh_host}"
            , when =
                None ProvisionerWhen
            , environment =
                []
            }
          , Provisioner.RemoteExec
            { inline =
                [ "echo \"Connection to ${local.ssh_host} established \"" ]
            , connection =
                None Connection
                -- [ { type = "ssh"
                --   , user = "change_this_default_user"
                --   -- , password = "change_this_default_password"
                --   , private_key = "${file(change_this)}"
                --   , host = "${local.ssh_host}"
            }
          -- , Provisioner.LocalExec
          --   { command =
          --       command =
          --         "ansible-playbook --limit \"kube-dev01" -e \"ansible_user=${local.default_user}\" --private-key=${local.default_private_key_file} -i \"${local.provision_dir}/inventory\" \"${local.provision_dir}/manage_users.yml\""
          ]
      }
    ]
}
