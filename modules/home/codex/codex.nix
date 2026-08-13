{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      codexPackage = inputs.codex-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.my.features.codex = lib.mkEnableOption "Codex CLI";
      config = lib.mkIf config.my.features.codex {
        # mkDefault so this composes with the richer wsl-work-home Codex
        # profile (programs.codex with MCP servers) without conflicting when
        # both features are enabled on the same host.
        programs.codex = lib.mkDefault {
          enable = true;
          package = codexPackage;
        };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.codex = homeModule;

  flake.modules.nixos.codex =
    { lib, ... }:
    {
      options.my.host.features.codex = lib.mkEnableOption "Codex CLI";
    };
}
