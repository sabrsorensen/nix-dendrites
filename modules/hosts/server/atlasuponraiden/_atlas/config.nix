{
  host = {
    primaryInteractiveUser = "sam";
    roles = {
      server = true;
      builder = true;
    };
    deploy = {
      canDeployRemotely = true;
      enableRemoteUser = true;
      sleepy = false;
    };
    ssh.enableNixBlocks = true;
    syncthing.mode = "system";
  };

  services = {
    my.services = {
      attic.enable = true;
      ankerctl.enable = true;
      apprise.enable = true;
      atuin.enable = true;
      frigate.enable = true;
      immich.enable = true;
      immich.mediaLocation = "/AnomalyRealm/media/photos";
      mealie.enable = true;
      minecraft.enable = true;
      monitoring = {
        enable = true;
        basicAuthPasswordEnvVar = "SCRUTINY_PASSWORD";
        blockyTargets = [
          "naboo"
          "nevarro"
        ];
      };
      podman.enable = true;
      samba.enable = true;
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
      scrutiny.enable = true;
      syncthing.server.enable = true;
    };
  };
}
