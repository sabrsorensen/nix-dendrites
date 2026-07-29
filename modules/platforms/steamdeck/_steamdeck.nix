{ inputs, ... }:
{
  imports = [
    (import ./_steamdeck/jovian.nix { inherit inputs; })
    (import ./_steamdeck/decky-loader.nix { })
    (import ./_steamdeck/decky-plugins.nix { })
    (import ./_steamdeck/decky-catalog.nix { })
  ];
}
