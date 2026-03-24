{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt;
      treefmt.programs.nixfmt.enable = true;
    };
}
