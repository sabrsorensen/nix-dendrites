{
  flake.modules.nixos.samba =
    { pkgs, ... }:
    {
      services.samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            security = "user";
            "workgroup" = "WORKGROUP";
            #"use sendfile" = "yes";
            #"max protocol" = "smb2";
            "hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };
        };
      };

      services.samba-wsdd = {
        enable = true;
        openFirewall = true;
      };

      networking.firewall.enable = true;
      networking.firewall.allowPing = true;
    };
}