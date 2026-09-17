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
  claudeSettings = "${config.home.homeDirectory}/.claude/settings.json";
  herdrPackage = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
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
        theme = "dark";
        agentPushNotifEnabled = true;
        inputNeededNotifEnabled = true;
      };
    };

    # Real-time usage monitor for Claude Code's local session logs.
    home.packages = with pkgs; [
      claude-monitor
    ];

    # Home Manager normally links settings.json from the Nix store
    # (read-only). Claude Code writes runtime state into it directly --
    # theme, notification toggles, hooks toggled on/off, etc. -- which fails
    # with EROFS against a store symlink. Mirror the Herdr config bridge
    # (see modules/home/herdr/_herdr-home.nix): turn the symlink into a
    # mutable copy once each generation has linked, so Claude Code can write
    # to it and you can try out settings at runtime -- the next switch
    # resets it back to what's declared above.
    home.activation.claudePrepareConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -f ${lib.escapeShellArg claudeSettings} ] && [ ! -L ${lib.escapeShellArg claudeSettings} ]; then
        run mv -f ${lib.escapeShellArg claudeSettings} ${lib.escapeShellArg "${claudeSettings}.claude-previous"}
      fi
    '';
    # Herdr's Claude Code integration (the SessionStart hook that used to
    # live only in settings.json.bak) is its own versioned installer -- see
    # `herdr integration status` -- so it's reinstalled here instead of
    # hand-copied, the same way the WSL Codex profile drives it (see
    # modules/platforms/wsl/wsl-work-home/codex/_codex.nix). Reinstalling
    # after the config is mutable keeps the hook registration and script in
    # sync with whatever herdr version is installed, on every switch.
    home.activation.claudeMutableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -L ${lib.escapeShellArg claudeSettings} ]; then
        run cp --remove-destination "$(readlink -f ${lib.escapeShellArg claudeSettings})" ${lib.escapeShellArg claudeSettings}
        # cp carries over the Nix store source's read-only mode bits (the
        # claude-code module builds settings.json with `install -Dm444`),
        # so the "mutable" copy comes out non-writable unless forced back.
        run chmod u+w ${lib.escapeShellArg claudeSettings}
      fi
      ${lib.optionalString config.my.features.herdr "run ${lib.getExe herdrPackage} integration install claude"}
    '';
  };
}
