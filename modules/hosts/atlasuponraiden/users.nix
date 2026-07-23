{ inputs, ... }:
{
  flake.modules.nixos.users-atlasuponraiden =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") {
      sops.secrets.hashed_password = {
        owner = "root";
        group = "root";
        mode = "0400";
        neededForUsers = true;
        sopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };
      users.users.sam = {
        isNormalUser = true;
        extraGroups = [
          "dialout"
          "docker"
          "networkmanager"
          "users"
        ];
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
      };
      users.groups.media = { };
      users.users.sonos = {
        isSystemUser = true;
        group = "media";
      };
      services.postgresql.settings.dynamic_shared_memory_type = "sysv";
      services.samba.settings = {
        global = {
          "server string" = "AtlasUponRaiden Samba";
          "server role" = "standalone server";
          "netbios name" = "atlasuponraiden";
          "hosts allow" = "192.168.1. 127.0.0.1 localhost";
        };
        media = {
          path = "/AnomalyRealm/media/";
          public = "no";
          writable = "yes";
          printable = "no";
          "valid users" = "sam";
        };
        music = {
          path = "/AnomalyRealm/media/music";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "sonos";
          "force user" = "sonos";
        };
      };
    };
}
