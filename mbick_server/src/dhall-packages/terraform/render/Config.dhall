let types = ../types.dhall


let renderProxmoxVM =
        \(vm : types.ProxmoxVM)
    ->  { name = vm.name
        , desc = "test description"
        , target_node = vm.node
        , clone = vm.template
        , cores = vm.cores
        , sockets = vm.sockets
        , memory = vm.memory
        , agent = 1 -- Activate agent for this VM
        , disk =
            { id = 0
            , type = "scsi"
            , size = vm.disk_gb
            , storage = "local-zfs"
            }
        , network =
            { id = 0
            , model = "virtio"
            , bridge = "vmbr0"
            }
        , os_type = "cloud-init"
        , ipconfig0 = "ip=${vm.ip},gw=${config.gateway}"
        }

let renderTFResource =
        \(resource : types.TFResource)
    ->  \(config : types.Config)
    ->  merge
        { ProxmoxVM =


in      \(deployment : types.TFDeployment)
    ->  let config = deployment.config
        let resources = deployment.resources
