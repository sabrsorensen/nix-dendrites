{ ... }:
{
  flake.modules.nixos.steam =
    { config, lib, ... }:
    {
      options.my.host.features.steam = lib.mkEnableOption "Steam";
      config = lib.mkIf config.my.host.features.steam (import ./_steam.nix { });
    };
}
