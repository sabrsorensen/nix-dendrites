{
  pkgs,
  ...
}:
{
  flake.modules.nixos.threedprinter =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        cura-appimage
        orca-slicer
      ];
    };
}
