let show =
      \(addr : ./Type.dhall)
  ->  merge
      {
      , Host = \(x : Text) -> x
      , IP = \(x : Text) -> x
      }
      addr

in show
