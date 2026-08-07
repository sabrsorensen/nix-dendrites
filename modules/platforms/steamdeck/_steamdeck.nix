{ inputs, ... }:
{
  imports = [
    (import ./_steamdeck/hardware/hardware.nix { })
    (import ./_steamdeck/boot-modes/dualboot.nix { })
    (import ./_steamdeck/boot-modes/singleboot.nix { })
    (import ./_steamdeck/jovian/jovian.nix { inherit inputs; })
    (import ./_steamdeck/decky-loader/decky-loader.nix { })
    (import ./_steamdeck/decky-plugins/decky-plugins.nix { })
    (import ./_steamdeck/decky-catalog/decky-catalog.nix { })
  ];
}
