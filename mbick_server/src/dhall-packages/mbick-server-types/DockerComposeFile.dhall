let Prelude = ../Prelude.dhall
let Location = Prelude.Location.Type

let networking = ../networking/package.dhall

in {
, name :
    Text
, file_path :
    Location
, host :
    ./DockerHost.dhall
}
