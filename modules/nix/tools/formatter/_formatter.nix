{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      formatter = config.treefmt.build.wrapper;
      treefmt.programs.nixfmt.enable = true;
    };
}
