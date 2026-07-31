args@{ lib, ... }:
lib.mkMerge [
  (import ./_base-content.nix args)
  (import ./_fail2ban-content.nix args)
]
