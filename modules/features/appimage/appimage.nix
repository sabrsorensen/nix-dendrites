{ ... }:
{
  # AppImage support is a local GUI component, so it is safe to broadcast and
  # self-gates on the host feature rather than being imported per workstation.
  flake.modules.nixos.appimage =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.appimage (import ./_appimage.nix { });
}
