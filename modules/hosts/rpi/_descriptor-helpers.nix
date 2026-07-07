{
  inputs,
  lib,
  network,
}:
let
  aarch64Helpers = import ../common/descriptors/_aarch64.nix { inherit inputs lib; };
  common = import ./_descriptor-common.nix { inherit inputs lib aarch64Helpers; };
  defaultNixosImports = [ inputs.self.modules.nixos."sam-system-cli" ];
  inherit (inputs.self.lib)
    localDns
    ;
in
rec {
  mkRpiDescriptor =
    {
      name,
      outputName,
      configuration,
      hostName ? name,
      systemType ? null,
      extraImports ? [ ],
      config ? { },
      myHost ? { },
      network ? { },
      deploy ? { },
      services ? { },
      outputs ? { },
      users ? { },
      bootstrap ? null,
    }:
    let
      normalizedNetwork = {
        mode = "static";
        inherit hostName;
        address = null;
        nameservers = [ ];
        localDnsRecords = [ ];
      }
      // network;
      normalizedDeploy = {
        method = "switch";
        remoteUser = null;
        secure = null;
      }
      // deploy;
      normalizedServices = {
        roles = [ ];
        imports = [ ];
        blocky = {
          enable = false;
        };
        dhcpCoredns = null;
      }
      // services;
      normalizedOutputs = {
        system.enable = true;
        image = {
          enable = false;
          name = null;
          outputName = null;
          configuration = null;
        };
        bootstrap = bootstrap;
      }
      // outputs;
      normalizedPrimaryUser = users.primary or null;
      normalizedUsers = {
        primary = normalizedPrimaryUser;
      };
      resolvedNixosImports = common.mkResolvedImports {
        inherit systemType extraImports;
        inherit defaultNixosImports;
        serviceImports = normalizedServices.imports;
      };
      resolvedConfig =
        lib.optionalAttrs normalizedServices.blocky.enable {
          my.services.blocky.enable = true;
        }
        // config;
      isService = normalizedDeploy.method == "secure" || normalizedServices.roles != [ ];
      inventoryOutputs =
        aarch64Helpers.mkAarch64Outputs {
          name = outputName;
          inherit configuration;
        }
        ++ common.mkImageInventoryOutputs normalizedOutputs.image
        ++ common.mkBootstrapInventoryOutputs normalizedOutputs.bootstrap;
      inventoryArgs = {
        outputs = inventoryOutputs;
        deployRemoteMethod = normalizedDeploy.method;
        extraInventory = lib.optionalAttrs (normalizedServices.roles != [ ]) {
          serviceRoles = normalizedServices.roles;
        };
      }
      // lib.optionalAttrs (normalizedPrimaryUser != null && normalizedPrimaryUser ? ssh) {
        userName = normalizedPrimaryUser.name;
        identityFile = normalizedPrimaryUser.ssh.identityFile;
        nixIdentityFile = normalizedPrimaryUser.ssh.nixIdentityFile;
      }
      // lib.optionalAttrs (normalizedDeploy.secure != null) {
        secureDeploy = {
          peerName = normalizedDeploy.secure.peer.name;
          peerIp = normalizedDeploy.secure.peer.ip;
          probeDomains = localDns.secureDeployProbeDomains;
        };
      };
    in
    {
      inherit
        bootstrap
        hostName
        name
        outputName
        ;
      config = resolvedConfig;
      my.host = myHost;
      nixos.imports = resolvedNixosImports;
      inventory = aarch64Helpers.mkAarch64Inventory inventoryArgs;
      network = normalizedNetwork;
      deploy = normalizedDeploy;
      services = normalizedServices;
      outputs = normalizedOutputs;
      users = normalizedUsers;
    };
}
