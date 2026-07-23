{ ... }:
{
  flake.modules.nixos.threedprinter =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.threedprinter {
      environment.systemPackages = [
        pkgs.cura-appimage
        pkgs.orca-slicer
      ];
    };
}
