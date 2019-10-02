let AbsoluteFilePath = ./AbsoluteFilePath.dhall

in  { project :
        AbsoluteFilePath
    , ansible :
        AbsoluteFilePath
    , ansible_inventory :
        AbsoluteFilePath
    }
