{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  flake.modules.nixos.base =
    args@{ config, lib, ... }: import ./_base.nix (args // { inherit domain; });
}
