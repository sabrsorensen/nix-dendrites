{ ... }:
{
  flake.modules.nixos.firmware =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.firmware (import ./_firmware.nix { });
}
