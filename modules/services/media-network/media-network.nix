{ ... }:
{
  flake.modules.nixos.media-network =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    import ./_content.nix args;
}
