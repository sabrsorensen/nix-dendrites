{ inputs }:
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
    programs.codex = lib.mkMerge [
      # mkDefault so this composes with the richer wsl-work-home Codex
      # profile (programs.codex with MCP servers) without conflicting when
      # both features are enabled on the same host.
      (lib.mkDefault {
        enable = true;
        package = codexPackage;
      })
      {
        plugins.context-mode = inputs.context-mode;
        # Superpowers agentic-skills framework (github:obra/superpowers).
        # The repo ships a .codex-plugin/plugin.json manifest, so Codex
        # loads its skills straight from the plugin source.
        plugins.superpowers = inputs.superpowers;
      }
    ];

    home.packages = with pkgs; [
      rtk
    ];
  };
}
