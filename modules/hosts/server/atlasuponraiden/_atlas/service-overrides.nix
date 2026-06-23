{
  config,
  ...
}:
let
  localDomain = config.systemConstants.domain;
in
{
  my.services = {
    ankerctl.enable = true;
    minecraft.enable = true;
    podman.enable = true;
  };

  # Enable server-mode Syncthing for AtlasUponRaiden.
  my.syncthing.enable = true;

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
    samba.settings = {
      global = {
        "server string" = "AtlasUponRaiden Samba";
        "server role" = "standalone server";
        "netbios name" = "atlasuponraiden";
        #"log level" = "3 smb:10 auth:3 smbd:10";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.1. 127.0.0.1 localhost";
      };
      "media" = {
        "path" = "/AnomalyRealm/media/";
        "public" = "no";
        "writable" = "yes";
        "printable" = "no";
        "valid users" = "sam";
      };
      "music" = {
        "path" = "/AnomalyRealm/media/music";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "sonos";
        "force user" = "sonos";
      };
    };
    # Work around intermittent POSIX shared-memory segment lookup failures
    # (`/PostgreSQL.*` ENOENT) by using SysV dynamic shared memory.
    postgresql.settings.dynamic_shared_memory_type = "sysv";
  };

  users.users.sonos = {
    isSystemUser = true;
    group = "media";
  };
}
