{
  flake.modules.nixos.samba =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.services.samba.enable = lib.mkEnableOption "Samba file sharing service";

      config = lib.mkIf config.my.services.samba.enable {
        services.samba = {
          enable = true;
          openFirewall = true;
          settings = {
            global = {
              security = "user";
              "workgroup" = "MYGROUP";
              "dns proxy" = "yes";
              "logging" = "systemd";
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
    };
}
