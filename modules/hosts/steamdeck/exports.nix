{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.steamdeck-home = ./_platform/steamdeck/steamdeck-home.nix;

  flake.modules.nixos = {
    steamdeck-decky-plugins = ./_platform/decky/decky-plugins.nix;
    steamdeck-plugins = ./_platform/decky/steamdeck-plugins.nix;
    steamdeck-system = ./_platform/steamdeck/steamdeck-system.nix;
  };

  flake.lib.steamdeck = import ./_public.nix { inherit inputs lib; };
}
