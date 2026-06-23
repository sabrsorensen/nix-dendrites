{
  flake.modules.nixos.printing =
    { config, lib, ... }:
    {
      options.my.services.printing.enable = lib.mkEnableOption "desktop printing and printer discovery";

      config = lib.mkIf config.my.services.printing.enable {
        services.printing.enable = true;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      };
    };
}
