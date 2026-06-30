{
  flake.modules.nixos.samba =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.samba;
    in
    {
      options.my.services.samba = {
        enable = lib.mkEnableOption "Samba file sharing service";

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Additional Samba settings merged on top of the shared defaults.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.samba = {
          enable = true;
          openFirewall = true;
          settings = lib.recursiveUpdate {
            global = {
              security = "user";
              "workgroup" = "MYGROUP";
              "dns proxy" = "yes";
              "logging" = "systemd";
            };
          } cfg.settings;
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
