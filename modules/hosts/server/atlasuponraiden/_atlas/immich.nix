{
  config,
  ...
}:
let
  readBuildValue =
    path:
    builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
  localDomain = readBuildValue "domain.txt";
in
{
  services = {
    immich = {
      mediaLocation = "/AnomalyRealm/media/photos";
      settings.server.externalDomain = "https://immich.${localDomain}/";
    };
    # Work around intermittent POSIX shared-memory segment lookup failures
    # (`/PostgreSQL.*` ENOENT) by using SysV dynamic shared memory.
    postgresql.settings.dynamic_shared_memory_type = "sysv";
    caddy = {
      virtualHosts."immich.{$DOMAIN}" = {
        logFormat = ''
          output stdout
          format console
          level INFO
        '';
        extraConfig = ''
          reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
        '';
      };
    };
  };
}