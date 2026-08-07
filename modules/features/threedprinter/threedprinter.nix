{ ... }:
{
  flake.modules.nixos.threedprinter =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.threedprinter (import ./_threedprinter.nix { inherit pkgs; });
}
