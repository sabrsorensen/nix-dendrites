let
  homeModule = import ./_stm32.nix;
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.stm32 = homeModule;

  flake.modules.nixos.stm32 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.stm32 = lib.mkEnableOption "STM32 development tools";

      config = lib.mkIf config.my.host.features.stm32 {
        # Home Manager uses the global pkgs, so this covers the user-level
        # toolchain and IDE in _stm32.nix.
        my.unfreePackageNames = [
          "stm32cubeide"
          "stm32cubemx"
        ];

        # Debug-probe access for the logged-in user (uaccess), so ST-Link /
        # OpenOCD / probe-rs flashing doesn't need root.
        services.udev.packages = [
          pkgs.openocd
          pkgs.probe-rs-tools
          pkgs.stlink
        ];
      };
    };
}
