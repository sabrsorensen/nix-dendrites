{ ... }:
{
  # Deployment is deliberately a normal broadcast module: host declarations
  # provide only facts and this module derives the operational policy.
  flake.modules.nixos.deployment =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.deployment;
      hasHashedPasswordSecret = config ? sops && config.sops.secrets ? hashed_password;
      enableRemoteUser = cfg.enableRemoteUser && hasHashedPasswordSecret;
      isAtlas = config.my.host.name == "AtlasUponRaiden";
      isWsl = config.my.host.roles.wsl;
      # nh 4.4.1 adds remote DIX snapshot queries.  Those queries currently
      # fail against our ssh-ng deployment stores, after the build completes.
      # Keep the previously deployed 4.4.0 until that upstream regression is
      # resolved, while retaining ssh-ng for remote builders and deployment.
      nh440Unwrapped = pkgs."nh-unwrapped".overrideAttrs (old: {
        version = "4.4.0";
        src = pkgs.fetchFromGitHub {
          owner = "nix-community";
          repo = "nh";
          tag = "v4.4.0";
          hash = "sha256-ebAi5ODaNRfhKISPPchWoI6FZNO2v+lEyvua7e5OOZo=";
        };
        cargoHash = "sha256-dRSueVz0BeWwYpMBO1KUUeRoa/CdCWsKPRw0Zeulfe8=";
      });
      nh440 = pkgs.nh.override { "nh-unwrapped" = nh440Unwrapped; };
      atlasBuilder = {
        hostName = "AtlasUponRaiden";
        protocol = "ssh-ng";
        sshUser = "nix-remote";
        sshKey = "/root/.ssh/nix_atlasuponraiden_id_ed25519";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "i686-linux"
        ];
        maxJobs = 4;
        speedFactor = 200;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      };
      remoteDeployRule = {
        users = [ "nix-remote" ];
        commands =
          map
            (command: {
              inherit command;
              options = [ "NOPASSWD" ];
            })
            [
              "/run/current-system/sw/bin/nixos-rebuild"
              "/run/current-system/sw/bin/nix-env"
              "/run/current-system/sw/bin/env"
              "/run/current-system/sw/bin/nix"
              "/nix/store/*/bin/switch-to-configuration"
            ];
      };
    in
    {
      config = {
        users.groups = lib.mkIf enableRemoteUser { nix-remote = { }; };
        users.users = lib.mkIf enableRemoteUser {
          nix-remote = {
            isSystemUser = true;
            description = "Nix remote deploy user";
            group = "nix-remote";
            home = "/home/nix-remote";
            createHome = true;
            shell = pkgs.bash;
            hashedPasswordFile = config.sops.secrets.hashed_password.path;
            openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
          };
        };
        # Ensure an existing deployment account also gains its declared home
        # directory when this option is introduced after the account exists.
        systemd.tmpfiles.rules = lib.optionals enableRemoteUser [
          "d /home/nix-remote 0750 nix-remote nix-remote -"
        ];
        security.sudo.extraRules = lib.optionals enableRemoteUser [ remoteDeployRule ];

        nix = {
          distributedBuilds = lib.mkDefault (!isWsl && !isAtlas);
          buildMachines = lib.mkDefault (lib.optionals (!isWsl && !isAtlas) [ atlasBuilder ]);
          settings = {
            # Keep local administration wheel-scoped; add the restricted
            # deployment account only on hosts that declare it.
            trusted-users = lib.mkAfter ([ "@wheel" ] ++ lib.optionals enableRemoteUser [ "nix-remote" ]);
            extra-substituters = lib.mkAfter (
              lib.optionals (!isWsl && !isAtlas) [
                "ssh-ng://nix-remote@AtlasUponRaiden?ssh-key=/root/.ssh/nix_atlasuponraiden_id_ed25519"
              ]
            );
          };
        };

        programs.nh = lib.mkIf (cfg.localFlakePath != null) {
          enable = true;
          package = nh440;
          clean.enable = true;
          clean.extraArgs = "--keep-since 4d --keep 3";
          flake = cfg.localFlakePath;
        };
      };
    };
}
