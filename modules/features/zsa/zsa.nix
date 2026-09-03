{ ... }:
{
  flake.modules.nixos.zsa =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.zsa = lib.mkEnableOption "ZSA tooling";
      config = lib.mkIf config.my.host.features.zsa (import ./_zsa.nix { inherit pkgs; });
    };
}
