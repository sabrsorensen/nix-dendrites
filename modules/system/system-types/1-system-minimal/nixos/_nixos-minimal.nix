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
      hasHashedPasswordSecret = config ? sops && config.sops.secrets ? hashed_password;
      enableNixRemote = config.my.host.deploy.enableRemoteUser && hasHashedPasswordSecret;
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
      imports = [
        inputs.self.modules.generic.systemConstants
        ../../../settings/host-context/host-context.nix
      ];

      #nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";
      console.keyMap = "dvorak";

      boot = {
        zfs.forceImportRoot = false;
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
          home = "/home/nix-remote/";
          shell = pkgs.bash;
          hashedPasswordFile = config.sops.secrets.hashed_password.path;
        };
      };
      security.sudo.extraRules = lib.optionals enableNixRemote [ remoteDeployRule ];

      nix = {
        buildMachines = config.my.host.nix.buildMachines;
        distributedBuilds = config.my.host.nix.buildMachines != [ ];
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
          extra-substituters = [
            "https://nix-gaming.cachix.org"
            "https://jovian-experiments.cachix.org"
            "https://cache.thalheim.io"
          ];
          extra-trusted-public-keys = [
            "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
            "jovian-experiments.cachix.org-1:lwPS3KgK5sJlI2B9KBY4VpbWNGbAjCcKVkUyqfzVrJE="
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
          trusted-users = [ "@wheel" ] ++ lib.optionals enableNixRemote [ "nix-remote" ];
          warn-dirty = false;
        };
      };

      environment.systemPackages = with pkgs; [
        dig.dnsutils
        htop
        openssl
        pciutils.out
        ps
        python3
        ripgrep
        vim
        wget
      ];
    };
}
