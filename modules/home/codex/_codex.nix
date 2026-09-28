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
        # codex >= 0.157 auto-starts a background app-server daemon, which
        # refuses to install unless it finds the official "complete package"
        # layout (codex-package.json beside bin/). codex-nix ships the bare
        # release binary, so every launch fails with "this CLI has no complete
        # local package" (openai/codex#48050). Restore the 0.156 default.
        settings.features.daemon_auto_start = false;
        plugins = [
          inputs.context-mode
          # Superpowers agentic-skills framework (github:obra/superpowers).
          # The repo ships a .codex-plugin/plugin.json manifest, so Codex
          # loads its skills straight from the plugin source.
          inputs.superpowers
        ];
      }
    ];

    warnings = [
      ''
        programs.codex sets features.daemon_auto_start = false because the
        codex-nix binary lacks the complete-package layout the 0.157 daemon
        installer requires (openai/codex#48050). Remove it from
        modules/home/codex/_codex.nix once the issue is fixed upstream and
        `codex --enable daemon_auto_start` starts normally -- check with:
          gh issue view 48050 -R openai/codex --json state,closedAt
      ''
    ];

    home.packages = with pkgs; [
    ];
  };
}
