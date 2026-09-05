{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  claudePackage = (pkgs.extend inputs.claude-code.overlays.default).claude-code;
  secretExports =
    lib.concatMapStringsSep "\n"
      (secret: ''
        if [ -r ${lib.escapeShellArg secret.path} ]; then
          export ${secret.name}="$(cat ${lib.escapeShellArg secret.path})"
        fi
      '')
      (
        builtins.filter (secret: secret.path != null) [
          {
            name = "CONTEXT7_API_KEY";
            path = lib.attrByPath [ "sops" "secrets" "context7_api_key" "path" ] null config;
          }
        ]
      );
  wrappedClaude = pkgs.symlinkJoin {
    name = "claude-code-wrapped-${lib.getVersion claudePackage}";
    paths = [ claudePackage ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/claude" --run ${lib.escapeShellArg secretExports}
    '';
  };
in
{
  options.my.features.claude = lib.mkEnableOption "Claude Code";
  config = lib.mkIf config.my.features.claude {
    programs.claude-code = {
      enable = true;
      package = wrappedClaude;
      plugins.context-mode = inputs.context-mode;
        # Superpowers agentic-skills framework (github:obra/superpowers),
        # installed as a personal plugin. The repo ships a
        # .claude-plugin/plugin.json manifest plus skills/ and
        # hooks/hooks.json, which Claude Code discovers automatically.
      plugins.superpowers = inputs.superpowers;
      settings = {
        statusLine = {
          type = "command";
          command = "context-mode statusline";
        };
      };
    };

    # Real-time usage monitor for Claude Code's local session logs.
    home.packages = with pkgs; [
      claude-monitor
      rtk
    ];
  };
}
