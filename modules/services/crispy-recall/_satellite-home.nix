{
  hubUrl,
  mkPackages,
  secretsFile,
  tokenKey,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.recall;
  inherit (mkPackages pkgs) recall;
  dist = "${recall}/lib/crispy-recall/dist";
  node = lib.getExe pkgs.nodejs_24;
  recallHome = "${config.home.homeDirectory}/.recall";
  # What `recall install` stages on a satellite. The Stop hook spawns
  # push-pending.js from ~/.recall/bin, so the layout has to match upstream's;
  # node resolves the symlinks back to the store for everything else.
  bundles = [
    "recall.js"
    "stop-hook.js"
    "push-pending.js"
    "statusline.js"
  ];
  recallCli = pkgs.writeShellScriptBin "recall" ''
    exec ${node} ${lib.escapeShellArg "${recallHome}/bin/recall.js"} "$@"
  '';
in
{
  options = {
    my.features.recall = lib.mkEnableOption "crispy-recall satellite";
    my.recall.hostName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Satellite name the hub token was issued for (crispy_recall/<name> in secrets.yaml).";
    };
  };

  # Everything `recall install --hub` would write, declared instead: its edits
  # to ~/.claude/settings.json would be reset by the next switch anyway.
  config = lib.mkIf config.my.features.recall {
    assertions = [
      {
        assertion = cfg.hostName != "";
        message = "crispy-recall satellite requires my.recall.hostName.";
      }
    ];

    home.packages = [ recallCli ];

    home.file =
      lib.genAttrs (map (b: ".recall/bin/${b}") bundles) (name: {
        source = "${dist}/${baseNameOf name}";
      })
      // {
        # A satellite has no database: a `satellite` record here is the switch
        # that makes every query and Stop hook talk to the hub instead.
        ".recall/config.json".text = builtins.toJSON {
          satellite = {
            inherit hubUrl;
            host = cfg.hostName;
            installedAt = "1970-01-01T00:00:00.000Z";
          };
        };
      };

    sops.secrets.${tokenKey cfg.hostName} = {
      sopsFile = secretsFile;
      path = "${recallHome}/satellite-token";
    };

    programs.claude-code = {
      skills.recall = builtins.replaceStrings [ "$RECALL_BIN" ] [ (lib.getExe recallCli) ] (
        builtins.readFile "${dist}/SKILL.md.template"
      );
      settings = {
        # The transcripts are the push spool: a laptop away from the LAN keeps
        # them until it can reach the hub again.
        cleanupPeriodDays = 999;
        # Same command shape `recall install` writes, so `recall doctor` and a
        # manual reinstall recognise it as recall's.
        hooks.Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = ''"${node}" "${recallHome}/bin/stop-hook.js"'';
              }
            ];
          }
        ];
      };
    };

    # The Stop hook only pushes the transcript that just finished a turn. An
    # hourly push also re-offers the recent set after time off the LAN, and
    # lets the hub escalate to its once-a-day full sweep, which backfills
    # transcripts from before the satellite was enrolled.
    systemd.user.services.recall-push = {
      Unit.Description = "Push Claude Code transcripts to the crispy-recall hub";
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe recallCli} push";
      };
    };
    systemd.user.timers.recall-push = {
      Unit.Description = "Push Claude Code transcripts to the crispy-recall hub";
      Timer = {
        OnStartupSec = "5min";
        OnUnitActiveSec = "1h";
        RandomizedDelaySec = "5min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
