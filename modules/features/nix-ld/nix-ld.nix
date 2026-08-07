{ ... }:
{
  flake.modules.nixos.nix-ld =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.nix-ld (import ./_nix-ld.nix { });
}
