{
  inputs,
  withSystem,
  ...
}:
{
  imports = [ inputs.pkgs-by-name-for-flake-parts.flakeModule ];

  flake.modules.generic.pkgs-by-name =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
      ];
    };

  perSystem =
    { system, ... }:
    {
      pkgsDirectory = inputs.packages;
    };

}
