{ ... }:
{
  flake.modules.nixos.samba =
    { config, lib, ... }:
    let
      cfg = config.my.samba;
    in
    {
      options.my.samba.settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional Samba settings merged on top of the shared defaults.";
      };
      config = lib.mkIf config.my.host.services.samba {
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

        networking.firewall = {
          enable = true;
          allowPing = true;
        };
      };
    };
}
