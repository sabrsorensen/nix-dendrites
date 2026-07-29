{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = { config, ... }: {
    formatter = config.treefmt.build.wrapper;
    treefmt.programs.nixfmt.enable = true;
  };
}
