let Prelude = ./Prelude.dhall
let Location = Prelude.Location.Type

let mbick-server-types = ../mbick-server-types/package.dhall


let renderPath =
      \(loc : Location)
  ->  merge {
      , Local =
          \(x : Text) -> x
      , Remote =
          \(x : Text) -> ""
      , Environment =
          \(x : Text) -> ""
      , Missing = ""
      }
      loc

let renderAnsiblePlaybookPath =
      \(lab_config : mbick-server-types.Config)
  ->  \(filename : Text)
  ->  "${renderPath lab_config.project_paths.ansible.playbooks}/${filename}"

let renderAnsibleInventoryPath =
      \(lab_config : mbick-server-types.Config)
  ->  renderPath lab_config.project_paths.ansible.inventory


in {
, renderAnsiblePlaybookPath =
    renderAnsiblePlaybookPath
, renderAnsibleInventoryPath =
    renderAnsibleInventoryPath
}
