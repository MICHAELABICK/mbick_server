let Prelude = ../Prelude.dhall

let types = ../types.dhall

let List/map = Prelude.List.map
let Map = Prelude.Map.Type
let Map/keyText = Prelude.Map.keyText
let Map/keyValue = Prelude.Map.keyValue
let JSON = Prelude.JSON


-- let renderQemuAgentEnable =
--           \(enable : Bool)
--       ->  if enable then 1 else 0 : Natural

-- let renderProxmoxDisk =
--           \(disk : types.ProxmoxDisk)
--       ->  let type =
--                 merge
--                 { SCSI = "scsi"
--                 }
--                 disk.type
--           in
--           { id = disk.id
--           , type = type
--           , size = disk.size_gb
--           , storage = disk.storage
--           }

-- let renderProxmoxNetworkDevice =
--           \(dev : types.ProxmoxNetworkDevice)
--       ->  let model =
--                 merge
--                 { VirtIO = "virtio"
--                 }
--                 dev.model
--           in
--           { id = dev.id
--           , model = model
--           , bridge = dev.bridge
--           }

-- let renderProxmoxOSType =
--           \(type : types.ProxmoxOSType)
--       ->  merge
--           { CloudInit = "cloud-init"
--           }
--           type
--           : Text

-- let renderProvisionerWhen =
--           \(value : types.ProvisionerWhen)
--       ->  merge
--           { destroy = JSON.string "destroy"
--           , none = JSON.null
--           }
--           value
--           : JSON.Type

-- let renderEnvironmentVariable =
--           \(var : types.EnvironmentVariable)
--       ->  Map/keyText var.name var.value

-- let renderEnvironmentVariables =
--           \(vars : List types.EnvironmentVariable)
--       ->  List/map
--           types.EnvironmentVariable
--           { mapKey : Text
--           , mapValue : Text
--           }
--           renderEnvironmentVariable
--           vars

-- let renderConnection =
--           \(con : types.Connection)
--       ->  { field = "type"
--           , nesting = JSON.Nesting.Inline
--           , contents = con
--           }


-- let Provisioner =
--       < LocalExec :
--           { command : Text
--           , when : JSON.Type
--           , environment : Map Text Text
--           }
--       | RemoteExec :
--           { inline : List Text
--           , connection : List types.Connection
--           }
--       >

-- let renderLocalExecProvisioner =
--           \(prov : types.LocalExecProvisioner)
--       ->  let value =
--                 Provisioner.LocalExec
--                 { command =
--                     prov.command
--                 , when =
--                     renderProvisionerWhen prov.when
--                 , environment =
--                     renderEnvironmentVariables prov.environment
--                 }
--           in Map/keyValue Provisioner "local-exec" value

-- let renderRemoteExecProvisioner =
--           \(prov : types.RemoteExecProvisioner)
--       -> let value =
--                 Provisioner.RemoteExec
--                 { inline : prov.inline
--                 , connection : [ prov.connection ]
--                 }
--           in Map/keyValue Provisioner "remote-exec" value

-- let renderProvisioner =
--           \(prov : types.Provisioner)
--       ->  merge
--           { LocalExec =
--               \(x : types.LocalExecProvisioner) -> renderLocalExecProvisioner x
--           , RemoteExec =
--               \(x : types.RemoteExecProvisioner) -> renderRemoteExecProvisioner x
--           }
--           prov


-- let renderProxmoxVM =
--             \(vm : types.ProxmoxVM)
--         ->  { name = vm.name
--             , desc = vm.description
--             , target_node = vm.target_node
--             , clone = vm.clone
--             , cores = vm.cores
--             , sockets = vm.sockets
--             , memory = vm.memory
--             , agent =
--                 renderQemuAgentEnable vm.agent
--             , disk =
--                 List/map
--                 types.ProxmoxDisk
--                 { id : Natural
--                 , type : Text
--                 , size : Natural
--                 , storage : Text
--                 }
--                 renderProxmoxDisk
--                 vm.disks
--             , network =
--                 List/map
--                 types.ProxmoxNetworkDevice
--                 { id : Natural
--                 , model : Text
--                 , bridge : Text
--                 }
--                 renderProxmoxNetworkDevice
--                 vm.network_devices
--             , os_type =
--                 renderProxmoxOSType vm.os_type
--             , ipconfig0 =
--                 "ip=${vm.ip}/${Natural/show vm.subnet.mask},gw=${config.gateway}"
--             , provisioner =
--                 List/map
--                 types.Provisioner
--                 { mapKey : Text
--                 , mapValue : Provisioner
--                 }
--                 renderProvisioner
--                 vm.provisioners
--             }

-- let renderResource =
--         \(res : types.Resource)
--     ->  merge
--         { ProxmoxVM = renderProxmoxVM
--         }
--         res


-- in
--     \(config : types.Config)
-- ->  { provider = []
--     , resource =
--         List/map
--         types.Resource
--         { mapKey : Text
--         , mapValue : types.Resource
--         }
--         config.resources
--     }

in
    \(config : types.Config)
->  {
    , provider = {
        , pm_tls_insecure = True
        , pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
        , pm_password = "secret"
        , pm_user = "terraform-user@pve"
        }
    }
