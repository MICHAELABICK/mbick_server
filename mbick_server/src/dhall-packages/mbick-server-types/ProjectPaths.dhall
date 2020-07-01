let Prelude = ../Prelude.dhall
let Location = Prelude.Location.Type

in {
, project :
    Location
, ansible :
    ./AnsiblePaths.dhall
}
