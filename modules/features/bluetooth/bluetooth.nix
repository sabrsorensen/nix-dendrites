{ ... }:
{
  flake.modules.nixos.bluetooth =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.bluetooth (import ./_content.nix { inherit config lib; });
}
