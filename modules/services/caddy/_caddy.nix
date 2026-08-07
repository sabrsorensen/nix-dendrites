args@{ lib, ... }:
lib.mkMerge [
  (import ./_caddy-base.nix args)
  (import ./_caddy-fail2ban.nix args)
]
