{ pkgs, ... }:
{
  services.samba = {
    settings = {
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
  };

  users.users.sonos = {
    isSystemUser = true;
    group = "media";
  };
}
