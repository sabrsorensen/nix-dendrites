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
      atlasBuilder = {
        hostName = "atlasuponraiden";
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
            shell = pkgs.bash;
            hashedPasswordFile = config.sops.secrets.hashed_password.path;
            openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
          };
        };
        security.sudo.extraRules = lib.optionals enableRemoteUser [ remoteDeployRule ];

        # Atlas is the predecessor's deployment and remote-build endpoint.
        # Keep its SFTP service available for that workflow without widening
        # access to the other SSH-enabled hosts.
        services.openssh.allowSFTP = lib.mkIf isAtlas true;

        nix = {
          distributedBuilds = lib.mkDefault (!isWsl && !isAtlas);
          buildMachines = lib.mkDefault (lib.optionals (!isWsl && !isAtlas) [ atlasBuilder ]);
          settings = {
            # Preserve the predecessor's local administrator trust boundary;
            # the restricted deployment account is added only where declared.
            trusted-users = lib.mkAfter ([ "@wheel" ] ++ lib.optionals enableRemoteUser [ "nix-remote" ]);
            extra-substituters = lib.mkAfter (
              lib.optionals (!isWsl && !isAtlas) [
                "ssh-ng://nix-remote@atlasuponraiden?ssh-key=/root/.ssh/nix_atlasuponraiden_id_ed25519"
              ]
            );
          };
        };

        programs.nh = lib.mkIf (cfg.localFlakePath != null) {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 4d --keep 3";
          flake = cfg.localFlakePath;
        };
      };
    };
}
