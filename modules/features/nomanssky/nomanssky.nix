{ ... }:
{
  flake.modules.nixos.nomanssky =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.noMansSky = lib.mkEnableOption "No Man's Sky tooling";
      config = lib.mkIf config.my.host.features.noMansSky (import ./_nomanssky.nix { inherit lib pkgs; });
    };
}
