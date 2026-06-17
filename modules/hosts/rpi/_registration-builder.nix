{
  inputs,
  lib,
  mkBaseModule,
  mkImageModule,
  mkServiceHostModule,
  mkStaticModule,
}:
{
  mkStaticHostRegistration =
    descriptor:
    let
      static = mkStaticModule {
        hostName = descriptor.network.hostName;
        address = descriptor.network.address;
      };
    in
    {
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.modules.nixos.${descriptor.name} = {
        imports = [
          (mkBaseModule descriptor.network.hostName)
        ]
        ++ static.imports;

        networking = static.networking;
        my.host = {
          address = descriptor.network.address;
          roles.rpi = true;
        };
        my.localDns.records = descriptor.localDnsRecords or [ ];

        boot.kernel.sysctl = lib.mkForce { };
      };
      flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" descriptor.name;
    };

  mkDhcpHostRegistration =
    descriptor:
    {
      flake.modules.nixos.${descriptor.name} = {
        imports = [
          (mkBaseModule descriptor.network.hostName)
        ];

        networking = {
          hostName = descriptor.network.hostName;
          useDHCP = true;
          interfaces.end0.useDHCP = true;
        };
        my.host.roles.rpi = true;
        boot.kernel.sysctl = lib.mkForce { };
      };
      flake.modules.nixos.${descriptor.image.name} = mkImageModule descriptor.name;
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.nixosConfigurations =
        inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
        // inputs.self.lib.mkNixos "aarch64-linux" descriptor.image.name;
    };

  mkServiceHostRegistration =
    descriptor:
    let
      staticDnsRecords = inputs.self.lib.localDns.staticRecords;
      baseModule = mkServiceHostModule {
        hostName = descriptor.name;
        address = descriptor.network.address;
        nameservers = descriptor.network.nameservers;
        serviceImports = descriptor.nixos.imports;
        samAuthorizedKeyPaths = descriptor.user.authorizedKeys.sam;
        nixRemoteAuthorizedKeyPaths = descriptor.user.authorizedKeys.nixRemote;
      };
      peer = descriptor.network.failoverPeer or null;
    in
    {
      flake.modules.nixos.${descriptor.name} = lib.mkMerge [
        baseModule
        {
          boot.kernel.sysctl = lib.mkForce { };

          my.host = {
            primaryInteractiveUser = descriptor.user.name;
            roles = {
              rpi = true;
              serviceHost = true;
            };
          };

          services.dhcp-coredns = {
            enable = true;
            interface = "end0";
            localDomainApexIp = descriptor.network.localDomainApexIp;
            upstreamServers = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            staticRecords = staticDnsRecords;
          }
          // lib.optionalAttrs (descriptor ? startKeaOnBoot) {
            startKeaOnBoot = descriptor.startKeaOnBoot;
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
      flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
      flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" descriptor.name;
    };
}
