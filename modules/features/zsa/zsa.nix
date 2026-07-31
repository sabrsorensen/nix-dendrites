{ ... }:
{
  flake.modules.nixos.zsa =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.zsa (import ./_content.nix { inherit pkgs; });
}
