{
  inputs,
  lib,
  ...
}:
{
  # Helper functions for creating system / home-manager configurations

  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkHomeManager = system: name: {
      ${name} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
          config.allowUnfree = true;
        };
        modules =
          lib.optionals (inputs ? determinate) [
            inputs.determinate.homeManagerModules.default
          ]
          ++ [
            inputs.self.modules.homeManager.${name}
            { nixpkgs.config.allowUnfree = true; }
          ];
      };
    };

    rpi =
      let
        network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
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
      rec {
        inherit network remoteDeployRule;

        mkBaseModule = hostName: {
          imports = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
            inputs.self.modules.nixos.samCli
            inputs.self.modules.nixos.system-cli
            ./../../hosts/rpi/_rpi/base.nix
          ];

          virtualisation.docker.enable = lib.mkForce false;
          virtualisation.podman.enable = lib.mkForce false;

          networking.hostName = hostName;
        };

        mkStaticModule =
          {
            hostName,
            address,
            nameservers ? [ ],
            extraImports ? [ ],
            extraConfig ? { },
          }:
          {
            imports = extraImports;

            networking = {
              hostName = hostName;
              useDHCP = false;
              interfaces.end0 = {
                useDHCP = false;
                ipv4.addresses = [
                  {
                    inherit address;
                    prefixLength = 24;
                  }
                ];
              };
              inherit nameservers;
            };
          }
          // extraConfig;

        mkImageModule =
          hostName:
          { config, pkgs, ... }:
          {
            imports = [
              (builtins.getAttr hostName inputs.self.modules.nixos)
              (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
            ];
            sdImage = {
              compressImage = false;
              expandOnBoot = true;
            };
            image.baseName = lib.mkDefault "${config.networking.hostName}-nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
          };
      };

  };
}
