{ ... }:
{
  flake.modules.nixos.nix-ld =
    { config, lib, ... }:
    {
      options.my.host.features.nix-ld = lib.mkEnableOption "nix-ld compatibility";
      config = lib.mkIf config.my.host.features.nix-ld (import ./_nix-ld.nix { });
    };
}
