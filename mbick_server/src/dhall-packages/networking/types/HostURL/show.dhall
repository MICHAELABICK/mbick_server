let HostAddress/show = ../HostAddress/show.dhall

let show =
      \(url : ./Type.dhall)
  ->  let protocol =
            merge
            {
            , HTTP = "http"
            , HTTPS = "https"
            , SSH = "ssh"
            , TCP = "tcp"
            }
            url.protocol
      let port =
            merge {
            , None = ""
            , Some = \(x : Natural) -> ":${Natural/show x}"
            }
            url.port
      let endpoint =
            merge {
            , None = ""
            , Some = \(x : Text) -> "/${x}"
            }
            url.endpoint
      in "${protocol}://${HostAddress/show url.host}${port}${endpoint}"

in show
