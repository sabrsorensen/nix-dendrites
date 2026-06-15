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
    hostInventory = { };
    localDns = { };
    site =
      let
        domain = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/domain.txt");
        network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
      in
      {
        inherit domain network;
        atlas = {
          systemFeatures = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
          ];
          supportedSystems = [
            "x86_64-linux"
            "aarch64-linux"
            "i686-linux"
          ];
          maxJobs = 4;
          speedFactor = 200;
        };
      };

    serviceRoleUnits = {
      "blocky-dns" = [
        "blocky"
        "coredns"
      ];
      "dhcp-primary" = [ "dhcp-coredns-kea" ];
      "dhcp-standby" = [ "dhcp-failover.timer" ];
    };

    expandServiceRoles =
      roles:
      lib.unique (lib.concatLists (map (role: inputs.self.lib.serviceRoleUnits.${role} or [ ]) roles));

    mkSecretsSshKeyFiles =
      keyPaths: map (keyPath: "${inputs.nix-secrets}/ssh-keys/${keyPath}.pub") keyPaths;

    mkHostOutput =
      {
        buildAttrPath,
        collection,
        configuration,
        kind,
        name,
        system,
      }:
      {
        inherit
          buildAttrPath
          collection
          configuration
          kind
          name
          system
          ;
      };

    mkNixosOutput =
      {
        collection,
        configuration,
        name,
        system,
        buildProduct ? "toplevel",
      }:
      inputs.self.lib.mkHostOutput {
        inherit
          collection
          configuration
          name
          system
          ;
        kind = "nixos";
        buildAttrPath = [
          "config"
          "system"
          "build"
          buildProduct
        ];
      };

    mkNixosOutputs =
      {
        collections ? [ "checks" ],
        configuration,
        name,
        system,
        buildProduct ? "toplevel",
      }:
      map (
        collection:
        inputs.self.lib.mkNixosOutput {
          inherit
            collection
            configuration
            name
            system
            buildProduct
            ;
        }
      ) collections;

    mkHomeOutput =
      {
        collection,
        configuration,
        name,
        system,
        buildAttrPath ? [ "activationPackage" ],
      }:
      inputs.self.lib.mkHostOutput {
        inherit
          buildAttrPath
          collection
          configuration
          name
          system
          ;
        kind = "home";
      };

    mkHomeOutputs =
      {
        collections ? [ "checks" ],
        configuration,
        name,
        system,
        buildAttrPath ? [ "activationPackage" ],
      }:
      map (
        collection:
        inputs.self.lib.mkHomeOutput {
          inherit
            collection
            configuration
            name
            system
            buildAttrPath
            ;
        }
      ) collections;

    mkInventorySshBase =
      {
        identityFile,
        user,
        identitiesOnly ? true,
        port ? null,
      }:
      {
        inherit identityFile identitiesOnly user;
      }
      // lib.optionalAttrs (port != null) { inherit port; };

    mkInventorySshNix =
      {
        identityFile,
        enable ? true,
        port ? null,
        user ? null,
      }:
      {
        inherit enable identityFile;
      }
      // lib.optionalAttrs (port != null) { inherit port; }
      // lib.optionalAttrs (user != null) { inherit user; };

    mkInventorySsh =
      {
        base,
        nix ? null,
      }:
      {
        inherit base;
      }
      // lib.optionalAttrs (nix != null) { inherit nix; };

    mkInventorySecureDeploy =
      {
        peerName,
        peerIp,
        probeDomains,
      }:
      {
        inherit peerIp peerName probeDomains;
      };

    mkInventoryDeploy =
      {
        remoteMethod ? "switch",
        secure ? null,
      }:
      {
        inherit remoteMethod;
      }
      // lib.optionalAttrs (secure != null) { inherit secure; };

    mkInventoryBuilder =
      {
        hostName,
        systems,
        maxJobs,
        speedFactor,
        supportedFeatures,
        mandatoryFeatures ? [ ],
        protocol ? "ssh-ng",
        publicHostKey ? null,
        sshKey ? null,
        sshUser ? "nix-remote",
        alias ? null,
      }:
      (
        {
          inherit
            hostName
            mandatoryFeatures
            maxJobs
            protocol
            publicHostKey
            sshKey
            sshUser
            speedFactor
            supportedFeatures
            systems
            ;
        }
        // lib.optionalAttrs (alias != null) { inherit alias; }
      );

    mkInventoryHost =
      {
        builder ? null,
        dnsConfigurations ? null,
        deploy ? null,
        outputs ? [ ],
        platform ? null,
        serviceRoles ? [ ],
        ssh ? null,
      }:
      (lib.optionalAttrs (builder != null) { inherit builder; })
      // (lib.optionalAttrs (ssh != null) { inherit ssh; })
      // (lib.optionalAttrs (dnsConfigurations != null) { inherit dnsConfigurations; })
      // (lib.optionalAttrs (deploy != null) { inherit deploy; })
      // (lib.optionalAttrs (platform != null) { inherit platform; })
      // (lib.optionalAttrs (serviceRoles != [ ]) { inherit serviceRoles; })
      // {
        inherit outputs;
      };

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkHomeManager =
      systemOrArgs:
      if builtins.isAttrs systemOrArgs then
        let
          args = systemOrArgs;
          name = args.name;
          system = args.system;
          hostName = args.hostName or name;
          hostContext = args.hostContext or null;
          extraSpecialArgs = args.extraSpecialArgs or { };
          extraConfig =
            args.extraConfig or (
              {
                ...
              }:
              { }
            );
          baseModules = args.modules or [ inputs.self.modules.homeManager.${name} ];
          hostDefaults =
            if hostContext == null then
              [ ]
            else
              [
                (
                  {
                    ...
                  }:
                  {
                    my.host = hostContext // {
                      name = hostName;
                      domain = inputs.self.lib.localDns.domain or null;
                    };
                    home.username = args.username;
                    home.homeDirectory = args.homeDirectory;
                    home.stateVersion = args.stateVersion;
                  }
                )
              ];
        in
        {
          ${name} = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
              config.allowUnfree = true;
            };
            extraSpecialArgs = {
              inventory = inputs.self.lib.hostInventory;
            }
            // extraSpecialArgs;
            modules =
              lib.optionals (inputs ? determinate) [
                inputs.determinate.homeManagerModules.default
              ]
              ++ baseModules
              ++ [
                { nixpkgs.config.allowUnfree = true; }
              ]
              ++ hostDefaults
              ++ [ extraConfig ];
          };
        }
      else
        name:
        inputs.self.lib.mkHomeManager {
          inherit name;
          system = systemOrArgs;
        };

    rpi =
      let
        network = inputs.self.lib.site.network;
      in
      rec {
        inherit network;

        mkBaseModule = hostName: {
          imports = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
            {
              _module.args.nixos-raspberrypi = inputs.nixos-raspberrypi;
              imports = [
                inputs.nixos-raspberrypi.nixosModules.trusted-nix-caches
                inputs.nixos-raspberrypi.nixosModules.nixpkgs-rpi
              ];
            }
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
            imports = extraImports ++ [ extraConfig ];

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
          };

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
