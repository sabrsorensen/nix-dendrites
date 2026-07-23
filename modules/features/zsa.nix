{ ... }:
{
  flake.modules.nixos.zsa =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.zsa {
      hardware.keyboard.zsa.enable = true;
      environment.systemPackages = [ pkgs.keymapp ];
      my.unfreePackageNames = [ "keymapp" ];
    };
}
