{
  flake.modules.nixos.xserver =
    { config, lib, ... }:
    lib.mkIf config.my.host.is.desktopSession {
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
