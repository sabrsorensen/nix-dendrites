{
  flake.modules.nixos.immich =
    { config, lib, ... }:
    {
      options.my.services.immich.enable = lib.mkEnableOption "Immich photo service";

      config = lib.mkIf config.my.services.immich.enable {
        services.immich = {
          enable = true;
          port = 2283;
          host = "127.0.0.1";
          openFirewall = true;
        };
      };
    };
}
