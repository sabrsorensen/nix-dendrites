# modules/home/example/example.nix
{ inputs, lib, ... }:
{
  flake-file.inputs.example = {
    url = "github:example/example";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Bootstrap-delayed: until `just write-flake` has added the input, the
  # module contributes nothing instead of failing evaluation.
  imports = lib.optional (inputs ? example) ./_example.nix;
}

# modules/home/example/_example.nix
{ inputs, ... }:
let
  homeModule =
    { pkgs, ... }:
    {
      programs.example = {
        enable = true;
        package = inputs.example.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
  featureModule =
    args@{ config, lib, ... }:
    {
      options.my.features.example = lib.mkEnableOption "Example";
      # The input's HM module must be safe to broadcast: audit its top-level
      # config for anything not behind its own enable option.
      imports = [ inputs.example.homeModules.default ];
      config = lib.mkIf config.my.features.example (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.example = featureModule;

  # Map at the HM boundary (modules/home/home/_home.nix):
  #   my.features.example = host.features.example;
  flake.modules.nixos.example =
    { lib, ... }:
    {
      options.my.host.features.example = lib.mkEnableOption "Example";
    };
}
