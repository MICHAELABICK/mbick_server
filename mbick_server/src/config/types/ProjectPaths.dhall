let AbsoluteFilePath = ./AbsoluteFilePath.dhall

in  { project_dir :
        AbsoluteFilePath
    , ansible_dir :
        AbsoluteFilePath
    , ansible_inventory_dir :
        AbsoluteFilePath
    }
