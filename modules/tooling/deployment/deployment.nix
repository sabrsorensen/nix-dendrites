{ ... }:
{
  # Deployment is deliberately a normal broadcast module: host declarations
  # provide only facts and this module derives the operational policy.
  flake.modules.nixos.deployment =
    args@{
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
      isWsl = config.my.host.platform == "wsl";
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
      config = import ./_deployment.nix (
        args
        // {
          inherit
            cfg
            enableRemoteUser
            isAtlas
            isWsl
            atlasBuilder
            remoteDeployRule
            ;
        }
      );
    };
}
