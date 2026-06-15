{
  config,
  ...
}:
let
  localDomain = config.systemConstants.domain;
in
{
  my.localDns.records = [
    { hostname = "immich"; }
  ];

  my.caddy.virtualHosts."immich.{$DOMAIN}" = {
    logFormat = ''
      output stdout
      format console
      level INFO
    '';
    routes = [
      ''
        reverse_proxy http://${config.services.immich.host}:${toString config.services.immich.port}
      ''
    ];
  };

  services = {
    immich = {
      mediaLocation = "/AnomalyRealm/media/photos";
      settings.server.externalDomain = "https://immich.${localDomain}/";
    };
    # Work around intermittent POSIX shared-memory segment lookup failures
    # (`/PostgreSQL.*` ENOENT) by using SysV dynamic shared memory.
    postgresql.settings.dynamic_shared_memory_type = "sysv";
  };
}
