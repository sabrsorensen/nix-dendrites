{
  pkgs,
  ...
}:
{
  flake.modules.nixos.threedprinter = {
    environment.systemPackages = with pkgs; [
      cura-appimage
      orca-slicer
    ];
  };
}