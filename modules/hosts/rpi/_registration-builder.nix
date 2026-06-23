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
rec {
  mkBootstrapHostModule =
    descriptor:
    let
      bootstrap = descriptor.bootstrap;
      bootstrapUser = bootstrap.user or { };
      bootstrapUserName = bootstrapUser.name or bootstrap.userName or "sam";
      shared = inputs.self.lib.shared;
      static =
        if descriptor.network.address == null then
          null
        else
          mkStaticModule {
            hostName = descriptor.network.hostName;
            address = descriptor.network.address;
            nameservers = descriptor.network.nameservers or [ ];
          };
    in
    {
      imports = [
        (mkBootstrapBaseModule descriptor.network.hostName)
      ]
      ++ lib.optionals (static != null) static.imports
      ++ bootstrap.nixos.imports;

      networking =
        if static != null then
          static.networking
        else
          {
            hostName = descriptor.network.hostName;
            useDHCP = true;
            interfaces.end0.useDHCP = true;
          };

      my.host = {
        lifecycle.mode = "bootstrap";
        bootstrap.finalConfigName = bootstrap.finalConfigName or descriptor.name;
        roles.rpi = true;
      }
      // lib.optionalAttrs (descriptor.network.address != null) {
        address = descriptor.network.address;
      }
      // lib.optionalAttrs (descriptor.kind == "service") {
        primaryInteractiveUser = descriptor.user.name;
        formFactor = "server";
        roles = {
          server = true;
          rpi = true;
          serviceHost = true;
        };
      };

      users.users.${bootstrapUserName} = {
        isNormalUser = true;
        extraGroups = bootstrapUser.extraGroups or [ "wheel" ];
        openssh.authorizedKeys.keyFiles = shared.mkSecretsSshKeyFiles bootstrap.authorizedKeyPaths;
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
    if descriptor.kind == "static" then
      mkStaticHostModule descriptor
    else if descriptor.kind == "service" then
      mkServiceHostModuleFromDescriptor descriptor
    else
      mkDhcpHostModule descriptor;

  mkStaticHostModule =
    descriptor:
    let
      static = mkStaticModule {
        hostName = descriptor.network.hostName;
        address = descriptor.network.address;
      };
    in
    {
      imports = [
        (mkBaseModule descriptor.network.hostName)
        descriptor.config
      ]
      ++ descriptor.nixos.imports
      ++ static.imports;

      networking = static.networking;
      my.host = {
        address = descriptor.network.address;
        roles.rpi = true;
      };
      my.localDns.records = descriptor.localDnsRecords or [ ];

      boot.kernel.sysctl = lib.mkForce { };
    };

  mkDhcpHostModule = descriptor: {
    imports = [
      (mkBaseModule descriptor.network.hostName)
      descriptor.config
    ]
    ++ descriptor.nixos.imports;

    networking = {
      hostName = descriptor.network.hostName;
      useDHCP = true;
      interfaces.end0.useDHCP = true;
    };
    my.host.roles.rpi = true;
    boot.kernel.sysctl = lib.mkForce { };
  };

  mkServiceHostModuleFromDescriptor =
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
    lib.mkMerge [
      baseModule
      descriptor.config
      {
        boot.kernel.sysctl = lib.mkForce { };

        my.host = {
          primaryInteractiveUser = descriptor.user.name;
          formFactor = "server";
          roles = {
            server = true;
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

  mkStaticHostRegistration = descriptor: {
    flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
    flake.modules.nixos = {
      ${descriptor.name} = mkStaticHostModule descriptor;
    }
    // lib.optionalAttrs (descriptor ? bootstrap && descriptor.bootstrap != null) {
      ${descriptor.bootstrap.configurationName} = mkBootstrapHostModule descriptor;
    };
    flake.nixosConfigurations =
      inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
      // lib.optionalAttrs (descriptor ? bootstrap && descriptor.bootstrap != null) (
        inputs.self.lib.mkNixos "aarch64-linux" descriptor.bootstrap.configurationName
      );
  };

  mkDhcpHostRegistration = descriptor: {
    flake.modules.nixos = {
      ${descriptor.name} = mkDhcpHostModule descriptor;
      ${descriptor.image.name} = mkImageModule descriptor.name;
    }
    // lib.optionalAttrs (descriptor ? bootstrap && descriptor.bootstrap != null) {
      ${descriptor.bootstrap.configurationName} = mkBootstrapHostModule descriptor;
      ${descriptor.bootstrap.imageName} = mkBootstrapImageModule descriptor.bootstrap.configurationName;
    };
    flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
    flake.nixosConfigurations =
      inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
      // inputs.self.lib.mkNixos "aarch64-linux" descriptor.image.name
      // lib.optionalAttrs (descriptor ? bootstrap && descriptor.bootstrap != null) (
        inputs.self.lib.mkNixos "aarch64-linux" descriptor.bootstrap.configurationName
        // inputs.self.lib.mkNixos "aarch64-linux" descriptor.bootstrap.imageName
      );
  };

  mkServiceHostRegistration = descriptor: {
    flake.modules.nixos = {
      ${descriptor.name} = mkServiceHostModuleFromDescriptor descriptor;
    }
    // lib.optionalAttrs (descriptor ? bootstrap && descriptor.bootstrap != null) {
      ${descriptor.bootstrap.configurationName} = mkBootstrapHostModule descriptor;
      ${descriptor.bootstrap.imageName} = mkBootstrapImageModule descriptor.bootstrap.configurationName;
    };
    flake.lib.hostInventory.${descriptor.name} = descriptor.inventory;
    flake.nixosConfigurations =
      inputs.self.lib.mkNixos "aarch64-linux" descriptor.name
      // lib.optionalAttrs (descriptor ? bootstrap && descriptor.bootstrap != null) (
        inputs.self.lib.mkNixos "aarch64-linux" descriptor.bootstrap.configurationName
        // inputs.self.lib.mkNixos "aarch64-linux" descriptor.bootstrap.imageName
      );
  };

  mkRegisteredHost =
    descriptor:
    if descriptor.kind == "static" then
      mkStaticHostRegistration descriptor
    else if descriptor.kind == "service" then
      mkServiceHostRegistration descriptor
    else
      mkDhcpHostRegistration descriptor;
}
