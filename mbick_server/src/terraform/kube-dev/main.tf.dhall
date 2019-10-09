let types = ../../config/types.dhall
let config = ../../config/config.dhall


let renderTFDeployment =
      ../../config/render/TFDeployment.dhall


let deployment : types.TFDeployment =
      { config = config
      , resources =
        [ types.ProxmoxVM
          { name = "kube-dev01"
          , node = "node1"
          , template = "ubuntu-bionic-1570324283"
          , cores = 2
          , sockets = 1
          , memory = 4096
          , disk_gb = 20
          , ip : "192.168.11.120"
          , groups =
              [ "ubuntu_bionic"
              , "k3s_control_node"
              ]
          }
        ]
      }

in renderTFDeployment deployment
