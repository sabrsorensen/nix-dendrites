args@{ lib, ... }:
lib.mkMerge [
  (import ./_core-content.nix args)
  (import ./_desktop-content.nix args)
  (import ./_users-content.nix args)
  (import ./_system-content.nix args)
]
