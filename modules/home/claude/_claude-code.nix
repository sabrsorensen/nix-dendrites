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
  # context-mode's bin/statusline.mjs dynamically imports a compiled
  # build/session/analytics.js for its real per-session/lifetime $ and %
  # savings. That build/ directory is gitignored upstream (produced by their
  # own `npm run build` before publishing) so it doesn't exist in the raw
  # `inputs.context-mode` flake input (a plain GitHub source fetch, no build
  # step) -- every statusline call there silently falls back to a hardcoded
  # "saves ~98% of context window" placeholder instead of real data. The
  # npm-published tarball does ship the prebuilt build/ directory, so pull
  # that separately just for the statusline CLI; the flake input is still
  # used as before for the Claude Code plugin (skills/hooks/MCP server),
  # which loads from the already-committed server.bundle.mjs and is
  # unaffected. Bump this version alongside inputs.context-mode if it drifts.
  contextModeCliVersion = "1.0.169";
  contextModeCli = pkgs.fetchzip {
    url = "https://registry.npmjs.org/context-mode/-/context-mode-${contextModeCliVersion}.tgz";
    hash = "sha256-ZZbcDagn2MC1dVZfNRIpNB4WwO4PVqHrP0rryoNkEmw=";
  };
  # Claude Code's statusLine. Its layout is ccstatusline-settings.json (an
  # export from its TUI); line two is a Custom Command widget running
  # context-mode's statusline, whose command ccstatusline runs through a shell.
  ccstatusline = pkgs.callPackage ./_ccstatusline.nix { };
  ccstatuslineSettingsFile = "${config.xdg.configHome}/ccstatusline/settings.json";
  ccstatuslineSettings =
    builtins.replaceStrings
      [ "@contextModeStatusline@" ]
      [ "${lib.getExe pkgs.nodejs} ${contextModeCli}/bin/statusline.mjs" ]
      (builtins.readFile ./ccstatusline-settings.json);
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
        enabledPlugins = {
          "context-mode@context-mode" = true;
        };
        hooks = {
          SessionStart = [
            {
              hooks = [
                {
                  command = "bash '/home/sam/.claude/hooks/herdr-agent-state.sh' session";
                  timeout = 10;
                  type = "command";
                }
              ];
              matcher = "^(startup|resume|clear|compact|fork)$";
            }
            {
              hooks = [
                {
                  command = "\"/home/sam/.claude/hooks/context-mode-cache-heal.mjs\"";
                  type = "command";
                }
              ];
            }
          ];
        };
        statusLine = {
          type = "command";
          command = lib.getExe ccstatusline;
          padding = 0;
          # Re-render every 10s so ccstatusline's usage and reset timers
          # advance while the session is idle.
          refreshInterval = 10;
        };
        theme = "dark";
        agentPushNotifEnabled = true;
        inputNeededNotifEnabled = true;
      };
    };

    # On PATH for its TUI; settings.statusLine.command above uses the store
    # path directly.
    home.packages = [ ccstatusline ];

    # Same mutable-copy bridge as settings.json below, so the ccstatusline TUI
    # can save while you try out layouts. The next switch resets it; export
    # from the TUI into ccstatusline-settings.json to keep a change.
    xdg.configFile."ccstatusline/settings.json".text = ccstatuslineSettings;
    home.activation.ccstatuslinePrepareConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -f ${lib.escapeShellArg ccstatuslineSettingsFile} ] && [ ! -L ${lib.escapeShellArg ccstatuslineSettingsFile} ]; then
        run mv -f ${lib.escapeShellArg ccstatuslineSettingsFile} ${lib.escapeShellArg "${ccstatuslineSettingsFile}.previous"}
      fi
    '';
    home.activation.ccstatuslineMutableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -L ${lib.escapeShellArg ccstatuslineSettingsFile} ]; then
        run cp --remove-destination "$(readlink -f ${lib.escapeShellArg ccstatuslineSettingsFile})" ${lib.escapeShellArg ccstatuslineSettingsFile}
        run chmod u+w ${lib.escapeShellArg ccstatuslineSettingsFile}
      fi
    '';

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
