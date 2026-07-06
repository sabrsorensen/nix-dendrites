{
  flake.modules.homeManager."sam-home-device-tools" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.my.host.features.gui {
        home.packages = with pkgs; [
          p7zip
          rclone
          stm32cubemx
        ];
      };
    };
}
