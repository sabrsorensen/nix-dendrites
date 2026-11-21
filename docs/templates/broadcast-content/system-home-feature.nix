# modules/features/example/example.nix
{ ... }:
let
  homeModule = import ./_example-home.nix;
  featureModule =
    args@{ config, lib, ... }:
    {
      options.my.features.example = lib.mkEnableOption "Example";
      config = lib.mkIf config.my.features.example (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.example = featureModule;

  # Map at the HM boundary (modules/home/home/_home.nix):
  #   my.features.example = host.features.example;
  flake.modules.nixos.example =
    args@{ config, lib, ... }:
    {
      options.my.host.features.example = lib.mkEnableOption "Example";
      # Add `&& config.my.host.home.enable` when the system half exists only
      # to support the user half (e.g. firewall ports for a desktop client).
      config = lib.mkIf config.my.host.features.example (import ./_example-nixos.nix args);
    };
}

# modules/features/example/_example-nixos.nix
{ ... }:
{
  programs.example.enable = true;
}

# modules/features/example/_example-home.nix
{ ... }:
{
  programs.example = {
    enable = true;
    # The NixOS half installs the package; don't install it twice.
    package = null;
    settings = { };
  };
}
