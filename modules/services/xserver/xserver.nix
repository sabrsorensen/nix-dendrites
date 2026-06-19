{
  flake.modules.nixos.xserver =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.gui {
      services.xserver = {
        enable = true;
        videoDrivers = [
          "nvidia"
          "intel"
          "modesetting"
        ];
      };
    };
}
