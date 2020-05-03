let HostAddress/show = ../HostAddress/show.dhall

let show =
      \(url : ./Type.dhall)
  ->  let protocol =
            merge
            {
            , HTTP = "http"
            , HTTPS = "https"
            , SSH = "ssh"
            }
            url.protocol
      let port =
            Optional/fold
            Natural
            url.port
            Text
            (\(x : Natural) -> ":${Natural/show x}")
            ""
      let endpoint =
            Optional/fold
            Text
            url.endpoint
            Text
            (\(x : Text ) -> "/${x}")
            ""
      in "${protocol}://${HostAddress/show url.host}${port}${endpoint}"

in show
