{
  config,
  inputs,
  lib,
  ...
}:
let
  payload = import ./_host.nix { inherit inputs lib; };
in
{
  flake.homeConfigurations.emeraldecho-steamos = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
    extraSpecialArgs = { inherit inputs; };
    # Same broadcast-and-gate composition as the NixOS managed-user boundary
    # (modules/home/home/_home.nix); feature flags mirror what sam-home sets
    # for a steamdeck-platform host.
    modules = config.dendritic.homeManagerModules ++ [
      { nixpkgs.config.allowUnfree = true; }
      payload.steamosLibraryModule
      inputs.sops-nix.homeManagerModules.sops
      inputs.self.modules.homeManager.syncthing-topology
      (
        { lib, pkgs, ... }:
        let
          domain = builtins.replaceStrings [ "\n" ] [ "" ] (
            builtins.readFile "${inputs.nix-secrets}/domain.txt"
          );
        in
        {
          # Non-NixOS integration: XDG_DATA_DIRS (so Plasma sees Nix .desktop
          # entries such as Firefox) and Mesa drivers for Nix-built apps.
          targets.genericLinux.enable = true;
          home.packages = import ../../../home/home/_packages.nix {
            inherit inputs lib pkgs;
            gui = true;
          };
          my.features = {
            atuin = true;
            bash = true;
            bitwarden = true;
            direnv = true;
            firefox = true;
            fish = true;
            git = true;
            "github-cli" = true;
            gpg = true;
            "nix-index" = true;
            sonos = true;
            sops = true;
            ssh = true;
            starship = true;
            steamdeck = true;
            syncthing = true;
            tmux = true;
            vim = true;
          };
          my.atuin.domain = domain;
          my.bash.isSteamDeck = true;
          my.fish = {
            local.enable = true;
            steamdeck.enable = true;
          };
          my.gpg.isGui = true;
          my.ssh = {
            inherit domain;
            hostName = "EmeraldEchoSteamOS";
          };
          my.sops.homeDirectory = "/home/deck";
          my.syncthingClient = {
            hostName = "EmeraldEchoSteamOS";
            isSteamDeck = true;
          };
          programs.home-manager.enable = true;
          programs.man.generateCaches = false;
        }
      )
    ];
  };
  flake.nixosConfigurations.emeraldecho = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.singleBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.singleBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootInstallerModule
      (payload.installerIso true)
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootInstallerModule
      (payload.installerIso true)
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.singleBootInstallerModule
      (payload.installerIso false)
    ];
  };
}
