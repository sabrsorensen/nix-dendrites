{
  inputs,
  ...
}:
{
  # default settings needed for all nixosConfigurations

  flake.modules.nixos.system-minimal =
    { pkgs, ... }:
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

      nix = {
        buildMachines = [
          {
            hostName = "sam@AtlasUponRaiden";
            systems = [ "x86_64-linux" ];
            protocol = "ssh";
            maxJobs = 8;
            speedFactor = 99; # Increased to prefer remote builds over emulation
            #supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "nix-command" "flakes" ];
            mandatoryFeatures = [ ];
          }
        ];
        distributedBuilds = true;
        extraOptions = ''
          warn-dirty = false
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
          parallel-building = true;
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
          trusted-users = [
            "root"
            "@wheel"
          ];
          warn-dirty = false;
        };
      };
    };
}
