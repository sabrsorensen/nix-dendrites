{ ... }:
{
  flake.modules.nixos.plymouth =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.plymouth (import ./_content.nix args);
}
