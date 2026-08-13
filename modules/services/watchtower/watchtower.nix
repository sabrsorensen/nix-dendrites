{ ... }:
{
  flake.modules.nixos.watchtower =
    { config, lib, ... }:
    {
      options.my.host.services.watchtower = lib.mkEnableOption "Watchtower container-update service";
      config = lib.mkIf config.my.host.services.watchtower (import ./_watchtower.nix { inherit config; });
    };
}
