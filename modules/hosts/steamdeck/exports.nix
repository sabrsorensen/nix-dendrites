{
  inputs,
  lib,
  ...
}:
let
  platformHelpers = import ./_platform-helpers.nix { inherit inputs; };
  registrationBuilder = import ./_registration-builder.nix {
    inherit lib;
    inherit (platformHelpers) steamdeck;
  };
in
{
  flake.modules.homeManager.steamdeck-home = ./_platform/steamdeck/steamdeck-home.nix;

  flake.modules.nixos = {
    steamdeck-decky-plugins = ./_platform/decky/decky-plugins.nix;
    steamdeck-plugins = ./_platform/decky/steamdeck-plugins.nix;
    steamdeck-system = ./_platform/steamdeck/steamdeck-system.nix;
  };

  flake.lib.steamdeck = {
    inherit (platformHelpers) steamdeck;
  }
  // registrationBuilder;
}
