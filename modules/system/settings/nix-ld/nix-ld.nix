{
  flake.modules.nixos.nix-ld =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.nix-ld {
      programs.nix-ld.enable = true;
    };
}
