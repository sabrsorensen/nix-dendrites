{
  pkgs,
  ...
}:
{
  flake.modules.nixos.threedprinter =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.threedprinter {
      environment.systemPackages = with pkgs; [
        cura-appimage
        orca-slicer
      ];
    };
}
