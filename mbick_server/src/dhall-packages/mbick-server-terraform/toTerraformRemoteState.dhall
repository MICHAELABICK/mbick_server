let types = ./types.dhall


let toTerraformRemoteState =
      \(terraform_config : types.Config.Type)
  ->  let remote_state =
            merge
            { S3 =
                \(x : types.S3Backend)
            ->  types.RemoteState.S3 {
                , name = terraform_config.name
                , backend = x
                , key = "${terraform_config.name}/terraform.tfstate"
                }
            }
            terraform_config.backend
      in remote_state : types.RemoteState

in toTerraformRemoteState
