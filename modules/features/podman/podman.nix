{ ... }:
{
  flake.modules.nixos.podman =
    { config, lib, ... }:
    {
      options.my.host.features.podman = lib.mkEnableOption "Podman container runtime";
      config = lib.mkIf config.my.host.features.podman (import ./_podman.nix { inherit config; });
    };
}
