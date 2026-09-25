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
  # Claude Code's statusLine hook only runs one command, but we want two
  # pieces of status on one line: cmonitor's official rate-limit/usage read,
  # then context-mode's savings line, joined with " | ". If cmonitor can't
  # produce a line, fall back to reading
  # `rate_limits.{five_hour,seven_day}.used_percentage` directly off stdin --
  # the same absent-field-tolerant read as
  # https://code.claude.com/docs/en/statusline#rate-limit-usage, since that
  # object is only present for Pro/Max subscribers after the first API call.
  claudeStatusline =
    pkgs.writers.writePython3Bin "claude-code-statusline" { flakeIgnore = [ "E501" ]; }
      ''
        """Claude Code statusLine: cmonitor + context-mode, one line each."""

        import json
        import re
        import subprocess
        import sys
        import time

        CMONITOR = "${pkgs.claude-monitor}/bin/cmonitor"
        NODE = "${lib.getExe pkgs.nodejs}"
        CONTEXT_MODE_CLI = "${contextModeCli}/bin/statusline.mjs"

        TIMEOUT_SECONDS = 5

        GREEN = "\033[32m"
        YELLOW = "\033[33m"
        RED = "\033[31m"
        RESET = "\033[0m"


        def run(cmd, stdin_bytes):
            try:
                result = subprocess.run(
                    cmd,
                    input=stdin_bytes,
                    capture_output=True,
                    timeout=TIMEOUT_SECONDS,
                    check=False,
                )
            except (OSError, subprocess.SubprocessError):
                return ""
            if result.returncode != 0:
                return ""
            return result.stdout.decode(errors="replace").strip()


        def bar_only(pct):
            pct = max(0.0, min(100.0, pct))
            color = RED if pct >= 90 else YELLOW if pct >= 70 else GREEN
            filled = int(pct) // 10
            bar = "█" * filled + "░" * (10 - filled)
            return f"{color}{bar}{RESET}"


        WINDOW_KEYS = {"5h": "five_hour", "7d": "seven_day"}


        # cmonitor doesn't expose resets_at itself, but it's right there on
        # stdin, straight from Anthropic's API -- compute a countdown from it
        # ourselves rather than trusting any tool's local-estimate guess.
        def time_left(resets_at):
            if resets_at is None:
                return None
            seconds = resets_at - time.time()
            if seconds <= 0:
                return None
            seconds = int(seconds)
            days, seconds = divmod(seconds, 86400)
            hours, seconds = divmod(seconds, 3600)
            minutes = seconds // 60
            if days:
                return f"{days}d{hours}h"
            if hours:
                return f"{hours}h{minutes}m"
            return f"{minutes}m"


        # cmonitor's own statusline text looks like "Sonnet · 5h 28% · 7d 64%"
        # (either window may be absent). Insert a colored bar (and a reset
        # countdown) between each window's label and its percentage rather than
        # reformatting the whole line, so whatever else cmonitor prints (model
        # name, cost, ...) is left untouched.
        RATE_LIMIT_RE = re.compile(r"(5h|7d) (\d+(?:\.\d+)?)%")


        def inject_bars(line, rate_limits):
            def replace(match):
                label, pct_str = match.group(1), match.group(2)
                window = (rate_limits.get(WINDOW_KEYS[label]) or {})
                left = time_left(window.get("resets_at"))
                suffix = f" ⏳{left}" if left else ""
                return f"{label} {bar_only(float(pct_str))} {pct_str}%{suffix}"

            return RATE_LIMIT_RE.sub(replace, line)


        def rate_limit_fallback(data):
            rate_limits = data.get("rate_limits") or {}
            parts = []
            for label, window in (("5h", "five_hour"), ("7d", "seven_day")):
                win = rate_limits.get(window) or {}
                pct = win.get("used_percentage")
                if pct is not None:
                    left = time_left(win.get("resets_at"))
                    suffix = f" ⏳{left}" if left else ""
                    parts.append(f"{label} {bar_only(pct)} {pct:.0f}%{suffix}")
            return " · ".join(parts)


        def main():
            raw = sys.stdin.buffer.read()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                data = {}
            rate_limits = data.get("rate_limits") or {}

            usage_line = run([CMONITOR, "--statusline"], raw)
            if usage_line:
                usage_line = inject_bars(usage_line, rate_limits)
            else:
                usage_line = rate_limit_fallback(data)

            context_mode_line = run([NODE, CONTEXT_MODE_CLI], raw)

            line = " | ".join(part for part in (usage_line, context_mode_line) if part)
            if line:
                print(line)


        if __name__ == "__main__":
            main()
      '';
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
          command = lib.getExe claudeStatusline;
        };
        theme = "dark";
        agentPushNotifEnabled = true;
        inputNeededNotifEnabled = true;
      };
    };

    # Real-time usage monitor for Claude Code's local session logs, plus the
    # composed statusline wrapper (also referenced by absolute store path in
    # settings.statusLine.command above) so it can be run and tested by hand.
    home.packages = with pkgs; [
      claude-monitor
      claudeStatusline
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
