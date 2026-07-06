{
  flake.modules.nixos.printing =
    { config, lib, ... }:
    let
      cfg = config.my.services.printing;
      autoEnable = config.my.host.is.workstation && !config.my.host.is.handheld;
    in
    {
      options.my.services.printing.enable = lib.mkEnableOption "desktop printing and printer discovery";

      config = lib.mkIf (cfg.enable || autoEnable) {
        services.printing.enable = true;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      };
    };
}
