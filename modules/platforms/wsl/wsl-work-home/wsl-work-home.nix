{ ... }:
let
  homeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.wslWorkHome = lib.mkEnableOption "WSL work Home Manager profile";
      config = lib.mkIf config.my.features.wslWorkHome (import ./_wsl-work-home.nix args);
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.wsl-work-home = homeModule;

  # The private work input supplies the SOPS secret declarations.  This module
  # owns only the portable WSL work tooling and is safe on every other host.
  flake.modules.nixos.wsl-work-home =
    { config, lib, ... }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      nixpkgs.config.permittedInsecurePackages = [
        "dotnet-sdk-6.0.428"
        "dotnet-sdk-7.0.410"
      ];
    };
}
