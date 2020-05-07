let packages = ./packages.dhall
let mbick-server = packages.mbick-server
in mbick-server.toPackerDefaults mbick-server.config
