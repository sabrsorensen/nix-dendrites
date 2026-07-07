{
  inputs,
  lib,
  mkBaseModule,
  mkImageModule,
  mkBootstrapBaseModule,
  mkBootstrapImageModule,
  mkServiceHostModule,
  mkStaticModule,
}:
let
  common = import ./_registration-common.nix { inherit lib; };
in
rec {
  mkBootstrapHostModule =
    descriptor:
    let
      bootstrap = common.descriptorBootstrap {
        inherit descriptor;
      };
      bootstrapUser = bootstrap.user or { };
      bootstrapUserName = bootstrapUser.name or bootstrap.userName or "sam";
      secrets = inputs.self.lib.secrets;
      static =
        if descriptor.network.address == null then
          null
        else
          mkStaticModule {
            hostName = common.descriptorHostName {
              inherit descriptor;
              fallbackToName = true;
            };
            address = descriptor.network.address;
            nameservers = descriptor.network.nameservers or [ ];
          };
    in
    {
      imports = [
        (mkBootstrapBaseModule (
          common.descriptorHostName {
            inherit descriptor;
            fallbackToName = true;
          }
        ))
      ]
      ++ lib.optionals (static != null) static.imports
      ++ bootstrap.nixos.imports;

      networking =
        if static != null then
          static.networking
        else
          {
            hostName = common.descriptorHostName {
              inherit descriptor;
              fallbackToName = true;
            };
            useDHCP = true;
            interfaces.end0.useDHCP = true;
          };

      my.host = common.mkBootstrapHostFacts {
        inherit descriptor;
      };

      users.users.${bootstrapUserName} = {
        isNormalUser = true;
        extraGroups = bootstrapUser.extraGroups or [ "wheel" ];
        openssh.authorizedKeys.keyFiles = secrets.mkSecretsSshKeyFiles bootstrap.authorizedKeyPaths;
      }
      // lib.optionalAttrs (bootstrapUser ? initialPassword) {
        initialPassword = bootstrapUser.initialPassword;
      };

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = lib.mkForce (bootstrapUser ? initialPassword);
      };

      boot.kernel.sysctl = lib.mkForce { };
    };

  mkHostModule =
    descriptor:
    if
      common.descriptorIsServiceHost {
        inherit descriptor;
      }
    then
      mkServiceHostModuleFromDescriptor descriptor
    else if
      common.descriptorNetworkMode {
        inherit descriptor;
      } == "dhcp"
    then
      mkDhcpHostModule descriptor
    else
      mkStaticHostModule descriptor;

  mkStaticHostModule =
    descriptor:
    let
      static = mkStaticModule {
        hostName = common.descriptorHostName {
          inherit descriptor;
          fallbackToName = true;
        };
        address = descriptor.network.address;
      };
    in
    {
      imports = [
        (mkBaseModule (
          common.descriptorHostName {
            inherit descriptor;
            fallbackToName = true;
          }
        ))
        descriptor.config
      ]
      ++ descriptor.nixos.imports
      ++ static.imports;

      networking = static.networking;
      my.host = common.mkStaticHostFacts {
        inherit descriptor;
      };
      my.localDns.records = descriptor.network.localDnsRecords;

      boot.kernel.sysctl = lib.mkForce { };
    };

  mkDhcpHostModule = descriptor: {
    imports = [
      (mkBaseModule (
        common.descriptorHostName {
          inherit descriptor;
          fallbackToName = true;
        }
      ))
      descriptor.config
    ]
    ++ descriptor.nixos.imports;

    networking = {
      hostName = common.descriptorHostName {
        inherit descriptor;
        fallbackToName = true;
      };
      useDHCP = true;
      interfaces.end0.useDHCP = true;
    };
    my.host = common.mkDhcpHostFacts {
      inherit descriptor;
    };
    boot.kernel.sysctl = lib.mkForce { };
  };

  mkServiceHostModuleFromDescriptor =
    descriptor:
    let
      staticDnsRecords = inputs.self.lib.localDns.staticRecords;
      baseModule = mkServiceHostModule {
        hostName = common.descriptorHostName {
          inherit descriptor;
          fallbackToName = true;
        };
        address = descriptor.network.address;
        nameservers = descriptor.network.nameservers;
        serviceImports = descriptor.nixos.imports;
        samAuthorizedKeyPaths = descriptor.users.primary.authorizedKeys.sam;
        nixRemoteAuthorizedKeyPaths = descriptor.users.primary.authorizedKeys.nixRemote;
      };
      dhcpCoredns = descriptor.services.dhcpCoredns or { };
      peer = dhcpCoredns.failoverPeer or null;
    in
    lib.mkMerge [
      baseModule
      descriptor.config
      {
        boot.kernel.sysctl = lib.mkForce { };

        my.host = common.mkServiceHostFacts {
          inherit descriptor;
        };

        my.services."dhcp-coredns" = {
          enable = true;
          interface = "end0";
          localDomainApexIp = dhcpCoredns.localDomainApexIp;
          upstreamServers = [
            "1.1.1.1"
            "9.9.9.9"
          ];
          staticRecords = staticDnsRecords;
        }
        // lib.optionalAttrs (dhcpCoredns ? startKeaOnBoot) {
          startKeaOnBoot = dhcpCoredns.startKeaOnBoot;
        }
        // lib.optionalAttrs (peer != null) {
          failover = {
            enable = true;
            peerName = peer.name;
            peerIp = peer.ip;
            probeDomains = peer.probeDomains;
          };
        };
      }
    ];

  mkStaticHostRegistration = descriptor: {
    flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
    flake.modules.nixos = {
      ${descriptor.name} = mkStaticHostModule descriptor;
    }
    //
      lib.optionalAttrs
        (
          common.descriptorBootstrap {
            inherit descriptor;
          } != null
        )
        {
          ${
            (common.descriptorBootstrap {
              inherit descriptor;
            }).configurationName
          } =
            mkBootstrapHostModule descriptor;
        };
    flake.nixosConfigurations =
      inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
      //
        lib.optionalAttrs
          (
            common.descriptorBootstrap {
              inherit descriptor;
            } != null
          )
          (
            inputs.self.lib.mkNixos "aarch64-linux"
              (common.descriptorBootstrap {
                inherit descriptor;
              }).configurationName
          );
  };

  mkDhcpHostRegistration =
    descriptor:
    let
      image = common.descriptorImage {
        inherit descriptor;
      };
    in
    {
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.modules.nixos = {
        ${descriptor.name} = mkDhcpHostModule descriptor;
      }
      // lib.optionalAttrs image.enable {
        ${image.name} = mkImageModule descriptor.name;
      }
      //
        lib.optionalAttrs
          (
            common.descriptorBootstrap {
              inherit descriptor;
            } != null
          )
          {
            ${
              (common.descriptorBootstrap {
                inherit descriptor;
              }).configurationName
            } =
              mkBootstrapHostModule descriptor;
            ${
              (common.descriptorBootstrap {
                inherit descriptor;
              }).imageName
            } =
              mkBootstrapImageModule
                (common.descriptorBootstrap {
                  inherit descriptor;
                }).configurationName;
          };
      flake.nixosConfigurations =
        inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
        // lib.optionalAttrs image.enable (inputs.self.lib.mkNixos "aarch64-linux" image.name)
        //
          lib.optionalAttrs
            (
              common.descriptorBootstrap {
                inherit descriptor;
              } != null
            )
            (
              inputs.self.lib.mkNixos "aarch64-linux"
                (common.descriptorBootstrap {
                  inherit descriptor;
                }).configurationName
              //
                inputs.self.lib.mkNixos "aarch64-linux"
                  (common.descriptorBootstrap {
                    inherit descriptor;
                  }).imageName
            );
    };

  mkServiceHostRegistration = descriptor: {
    flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
    flake.modules.nixos = {
      ${descriptor.name} = mkServiceHostModuleFromDescriptor descriptor;
    }
    //
      lib.optionalAttrs
        (
          common.descriptorBootstrap {
            inherit descriptor;
          } != null
        )
        {
          ${
            (common.descriptorBootstrap {
              inherit descriptor;
            }).configurationName
          } =
            mkBootstrapHostModule descriptor;
          ${
            (common.descriptorBootstrap {
              inherit descriptor;
            }).imageName
          } =
            mkBootstrapImageModule
              (common.descriptorBootstrap {
                inherit descriptor;
              }).configurationName;
        };
    flake.nixosConfigurations =
      inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
      //
        lib.optionalAttrs
          (
            common.descriptorBootstrap {
              inherit descriptor;
            } != null
          )
          (
            inputs.self.lib.mkNixos "aarch64-linux"
              (common.descriptorBootstrap {
                inherit descriptor;
              }).configurationName
            //
              inputs.self.lib.mkNixos "aarch64-linux"
                (common.descriptorBootstrap {
                  inherit descriptor;
                }).imageName
          );
  };

  mkRegisteredHost =
    descriptor:
    if
      common.descriptorIsServiceHost {
        inherit descriptor;
      }
    then
      mkServiceHostRegistration descriptor
    else if
      common.descriptorNetworkMode {
        inherit descriptor;
      } == "dhcp"
    then
      mkDhcpHostRegistration descriptor
    else
      mkStaticHostRegistration descriptor;
}
