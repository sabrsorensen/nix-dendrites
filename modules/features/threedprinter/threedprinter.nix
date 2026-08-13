{ ... }:
{
  flake.modules.nixos.threedprinter =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.threedprinter = lib.mkEnableOption "3D-printer tooling";
      config = lib.mkIf config.my.host.features.threedprinter (
        import ./_threedprinter.nix { inherit pkgs; }
      );
    };
}
