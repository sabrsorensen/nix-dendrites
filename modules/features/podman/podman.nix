{ ... }:
{
  flake.modules.nixos.podman =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.podman (import ./_content.nix { inherit config; });
}
