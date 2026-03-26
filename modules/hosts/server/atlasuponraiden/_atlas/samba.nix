{ pkgs, ... }:
{
  services.samba = {
    settings = {
      global = {
        "server string" = "AtlasUponRaiden";
        "netbios name" = "atlasuponraiden";
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
        "public" = "yes";
        "writable" = "no";
        "printable" = "no";
        "valid users" = "sonos";
      };
    };
  };

  users.groups.sonos = {};
  users.users.sonos = {
    isNormalUser = false;
    isSystemUser = true;
    description = "Sonos";
    group = "sonos";
    extraGroups = [ ];
    shell = pkgs.bash;
  };
}