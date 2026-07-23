{ ... }:
{
  # AppImage support is a local GUI capability, so it is safe to broadcast and
  # self-gates on the host fact rather than being imported per workstation.
  flake.modules.nixos.appimage =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.gui {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
}
