{ pkgs }:
{
  environment.systemPackages = with pkgs; [
    cura-appimage
    orca-slicer
  ];
}
