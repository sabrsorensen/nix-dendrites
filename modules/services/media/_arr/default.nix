{ lib }:
let
  mkLocalAddr = bindAddr: port: "${bindAddr}:${lib.toString port}";

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

  mkModule =
    {
      serviceName,
      serviceConfig,
      routeSpecs,
      user ? serviceName,
      group ? "media",
      setUserGroup ? true,
      managedServices ? { },
    }:
    lib.mkMerge [
      {
        my.media.caddy.apexRoutes = map (
          routeSpec:
          mkThemeParkRoute (
            (builtins.removeAttrs routeSpec [
              "bindAddr"
              "port"
            ])
            // {
              inherit serviceName;
              localAddr = routeSpec.localAddr or (mkLocalAddr (routeSpec.bindAddr or "127.0.0.1") routeSpec.port);
            }
          )
        ) routeSpecs;

        services.${serviceName} = serviceConfig;
      }
      (lib.optionalAttrs setUserGroup {
        users.users.${user}.group = group;
      })
      (lib.optionalAttrs (managedServices != { }) {
        systemd.services = managedServices;
      })
    ];
in
{
  inherit mkLocalAddr mkManagedService mkModule mkThemeParkRoute;
}
