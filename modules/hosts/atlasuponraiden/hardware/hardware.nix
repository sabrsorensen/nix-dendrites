{ inputs, lib, ... }:
let
  domain = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/domain.txt");
in
{
  flake.modules.nixos.hardware-atlasuponraiden =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") (
      import ./_hardware.nix (args // { inherit domain; })
    );
}
