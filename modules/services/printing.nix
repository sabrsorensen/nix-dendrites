{ ... }:
{
  flake.modules.nixos.printing =
    { config, lib, ... }:
    lib.mkIf (config.my.host.is.workstation && !config.my.host.is.steamdeck) {
      services.printing.enable = true;
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
}
