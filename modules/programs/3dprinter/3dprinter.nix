{
  pkgs,
  ...
}:
{
  flake.modules.nixos."3dprinter" = {
    environment.systemPackages = with pkgs; [
      cura-appimage
      orca-slicer
    ];
  };
}