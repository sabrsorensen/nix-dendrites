{ ... }:
{
  flake.modules.nixos.media-network =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    import ./_media-network.nix args;
}
