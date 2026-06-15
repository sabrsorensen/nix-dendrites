{ lib }:
let
  mkThemeParkRoute =
    {
      serviceName,
      localAddr,
      marker ? "</body>",
      pathSuffix ? "",
    }:
    let
      routeName = "${serviceName}${pathSuffix}";
    in
    ''
      redir /${routeName} /${routeName}/
      route /${routeName}/* {
        filter {
          content_type text/html.*
          search_pattern ${marker}
          replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'>${marker}"
        }
        reverse_proxy /${routeName}/* ${localAddr} {
          header_up -Accept-Encoding
        }
      }
    '';

  mkManagedService =
    {
      description,
      execStart,
      user,
      group,
      extraServiceConfig ? { },
    }:
    {
      inherit description;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = execStart;
        Restart = "always";
        User = user;
        Group = group;
      }
      // extraServiceConfig;
    };
in
{
  inherit mkThemeParkRoute mkManagedService;
}
