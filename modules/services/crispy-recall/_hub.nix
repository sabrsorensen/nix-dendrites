{
  config,
  lib,
  pkgs,
  hubAddress,
  lanCidr,
  mkPackages,
  port,
  satellites,
  secretsFile,
  tokenKey,
  ...
}:
let
  user = "crispy-recall";
  stateDir = "/var/lib/crispy-recall";
  inherit (mkPackages pkgs) recall llama model;
  dist = "${recall}/lib/crispy-recall/dist";
  node = lib.getExe pkgs.nodejs_24;
  portStr = toString port;
  # What `recall install` stages on a hub. The daemon spawns embed-pending.js
  # from bin/ and checks bin/llama-embedding + models/ before it serves.
  bundles = [
    "recall.js"
    "stop-hook.js"
    "embed-pending.js"
    "push-pending.js"
    "statusline.js"
  ];

  prepare = pkgs.writeShellApplication {
    name = "crispy-recall-hub-prepare";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      state=${lib.escapeShellArg stateDir}
      install -d -m 0700 "$state/bin" "$state/models"
      ${lib.concatMapStringsSep "\n" (
        b: ''ln -sfn ${lib.escapeShellArg "${dist}/${b}"} "$state/bin/${b}"''
      ) bundles}
      ln -sfn ${llama}/bin/llama-embedding "$state/bin/llama-embedding"
      ln -sfn ${llama}/bin/llama-server "$state/bin/llama-server"
      ln -sfn ${model} "$state/models/nomic-embed-text-v1.5.Q8_0.gguf"

      # `hub serve` refuses to start without a database; an empty file is a
      # fresh one it initializes at the current schema.
      if [ ! -e "$state/recall.db" ]; then
        : > "$state/recall.db"
      fi

      # hub-tokens.json holds only sha256(token) per satellite and is re-read on
      # every request. Rebuilt from the sops secrets on each start, so
      # `recall hub token` changes don't survive a restart: rotate in sops.
      tokens='{}'
      for host in ${lib.escapeShellArgs satellites}; do
        hash=$(tr -d '[:space:]' < "$CREDENTIALS_DIRECTORY/$host" | sha256sum | cut -d' ' -f1)
        tokens=$(jq --arg hash "$hash" --arg host "$host" \
          '. + {($hash): {host: $host, createdAt: ""}}' <<<"$tokens")
      done
      jq -n --argjson tokens "$tokens" '{v: 1, tokens: $tokens}' > "$state/hub-tokens.json.tmp"
      chmod 0600 "$state/hub-tokens.json.tmp"
      mv -f "$state/hub-tokens.json.tmp" "$state/hub-tokens.json"
    '';
  };

  # Admin CLI as the service user: `recall-hub hub status`, `recall-hub doctor`,
  # `recall-hub --all "query"`.
  recallHub = pkgs.writeShellScriptBin "recall-hub" ''
    cd /
    exec /run/wrappers/bin/sudo -u ${user} \
      ${pkgs.coreutils}/bin/env RECALL_HOME=${stateDir} HOME=${stateDir} \
      ${node} ${stateDir}/bin/recall.js "$@"
  '';

  firewallRule = "-p tcp -s ${lanCidr} --dport ${portStr} -j nixos-fw-accept";
in
{
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    home = stateDir;
  };
  users.groups.${user} = { };

  sops.secrets = lib.genAttrs (map tokenKey satellites) (_: {
    sopsFile = secretsFile;
  });

  environment.systemPackages = [ recallHub ];

  networking.firewall.extraCommands = lib.mkIf (!config.networking.nftables.enable) ''
    iptables -A nixos-fw ${firewallRule}
  '';
  networking.firewall.extraStopCommands = lib.mkIf (!config.networking.nftables.enable) ''
    iptables -D nixos-fw ${firewallRule} || true
  '';
  networking.firewall.extraInputRules = lib.mkIf config.networking.nftables.enable ''
    ip saddr ${lanCidr} tcp dport ${portStr} accept
  '';

  systemd.services.crispy-recall-hub = {
    description = "crispy-recall hub (transcript index for recall satellites)";
    wantedBy = [ "multi-user.target" ];
    # Binds the LAN address itself, which has to exist first.
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    environment = {
      RECALL_HOME = stateDir;
      HOME = stateDir;
    };
    serviceConfig = {
      User = user;
      Group = user;
      StateDirectory = "crispy-recall";
      StateDirectoryMode = "0700";
      WorkingDirectory = stateDir;
      LoadCredential = map (host: "${host}:${config.sops.secrets.${tokenKey host}.path}") satellites;
      ExecStartPre = lib.getExe prepare;
      ExecStart = "${node} ${stateDir}/bin/recall.js hub serve --bind ${hubAddress} --port ${portStr}";
      Restart = "on-failure";
      RestartSec = 10;

      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };
}
