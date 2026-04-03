{
  inputs,
  ...
}:
{
  # default settings needed for all nixosConfigurations

  flake.modules.nixos.system-minimal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isWsl = config.wsl.enable or false;
      hasHashedPasswordSecret = config ? sops && config.sops.secrets ? hashed_password;
      enableNixRemote = !isWsl && hasHashedPasswordSecret;
      remoteDeployRule = {
        users = [ "nix-remote" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-env";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/env";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/store/*/bin/switch-to-configuration";
            options = [ "NOPASSWD" ];
          }
        ];
      };
    in
    {
      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) config;
            system = pkgs.stdenv.hostPlatform.system;
          };
        })
      ];
      #nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";
      console.keyMap = "dvorak";

      boot = {
        tmp = {
          useTmpfs = true;
          cleanOnBoot = true;
        };
      };

      users.groups = lib.mkIf enableNixRemote {
        nix-remote = { };
      };
      users.users = lib.mkIf enableNixRemote {
        nix-remote = {
          isSystemUser = true;
          description = "Nix remote deploy user";
          group = "nix-remote";
          home = "/var/empty";
          shell = pkgs.bash;
          hashedPasswordFile = config.sops.secrets.hashed_password.path;
          openssh.authorizedKeys.keyFiles = [
          ];
        };
      };
      security.sudo.extraRules = lib.optionals enableNixRemote [ remoteDeployRule ];

      nix = {
        buildMachines = [
          {
            hostName = "sam@AtlasUponRaiden";
            systems = [
              "x86_64-linux"
              "aarch64-linux"
              "i686-linux"
            ];
            protocol = "ssh";
            maxJobs = 8;
            speedFactor = 99; # Increased to prefer remote builds over emulation
            mandatoryFeatures = [ ];
          }
        ];
        distributedBuilds = true;
        extraOptions = ''
          warn-dirty = false
        ''
        + lib.optionalString (config ? sops && config.sops.secrets ? github_nixos_token) ''
          !include ${config.sops.secrets.github_nixos_token.path}
        '';
        settings = {
          auto-optimise-store = true;
          builders-use-substitutes = true;
          cores = 0;
          download-buffer-size = 1024 * 1024 * 1024;
          experimental-features = [
            "nix-command"
            "flakes"
            # "allow-import-from-derivation"
          ];
          extra-substituters = [ "https://cache.thalheim.io" ];
          extra-trusted-public-keys = [
            "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
          ];
          keep-derivations = true;
          keep-outputs = true;
          max-jobs = "auto";
          substituters = [
            # high priority since it's almost always used
            "https://cache.nixos.org?priority=10"
            "https://install.determinate.systems"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          trusted-users =
            [ "@wheel" ]
            ++ lib.optionals enableNixRemote [ "nix-remote" ];
          warn-dirty = false;
        };
      };

      environment.systemPackages = with pkgs; [
        dig.dnsutils
        htop
        openssl
        pciutils.out
        ps
        ripgrep
        vim
        wget
      ];

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/sam/src/nix-dendrites";
      };
    };
}
