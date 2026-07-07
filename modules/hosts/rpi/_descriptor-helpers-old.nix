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
  mkStaticDescriptor =
    {
      address,
      config ? { },
      configuration,
      hostName,
      localDnsRecords ? [ ],
      name,
      systemType ? null,
      outputName,
      extraImports ? [ ],
      bootstrap ? null,
    }:
    let
      resolvedNixosImports = common.mkResolvedImports {
        inherit defaultNixosImports systemType extraImports;
      };
    in
    {
      kind = "static";
      inherit
        bootstrap
        config
        localDnsRecords
        name
        outputName
        ;
      nixos.imports = resolvedNixosImports;
      network = {
        inherit address hostName;
      };
      inventory = aarch64Helpers.mkAarch64Inventory {
        deployRemoteMethod = "switch";
        outputs = aarch64Helpers.mkAarch64Outputs {
          name = outputName;
          inherit configuration;
        };
      };
    };

  mkDhcpDescriptor =
    {
      config ? { },
      configuration,
      hostName,
      imageName,
      imageOutputName,
      name,
      systemType ? null,
      outputName,
      extraImports ? [ ],
      bootstrap ? null,
    }:
    let
      resolvedNixosImports = common.mkResolvedImports {
        inherit defaultNixosImports systemType extraImports;
      };
      image = {
        enable = true;
        name = imageName;
        outputName = imageOutputName;
        configuration = imageName;
      };
    in
    {
      kind = "dhcp";
      inherit
        bootstrap
        config
        name
        outputName
        ;
      nixos.imports = resolvedNixosImports;
      image = image;
      network = {
        inherit hostName;
        address = null;
        dhcp = true;
      };
      inventory = aarch64Helpers.mkAarch64Inventory {
        deployRemoteMethod = "switch";
        outputs =
          aarch64Helpers.mkAarch64Outputs {
            name = outputName;
            inherit configuration;
          }
          ++ common.mkImageInventoryOutputs image
          ++ common.mkBootstrapInventoryOutputs bootstrap;
      };
    };

  mkServiceDescriptor =
    {
      address,
      authorizedKeys,
      config ? { },
      configuration,
      failoverPeer ? null,
      imageName,
      imageOutputName,
      identityFile,
      localDomainApexIp,
      name,
      nameservers,
      nixIdentityFile,
      outputName,
      securePeer,
      serviceRoles,
      startKeaOnBoot ? null,
      userName ? "sam",
      systemType ? null,
      extraImports ? [ ],
      bootstrap ? null,
    }:
    let
      resolvedNixosImports = common.mkResolvedImports {
        defaultNixosImports =
          (with inputs.self.modules.nixos; [
            blocky
            dhcp-coredns
          ])
          ++ defaultNixosImports;
        inherit systemType extraImports;
      };
      image = {
        enable = true;
        name = imageName;
        outputName = imageOutputName;
        configuration = imageName;
      };
    in
    {
      kind = "service";
      inherit
        bootstrap
        name
        outputName
        ;
      config = lib.recursiveUpdate {
        my.services.blocky.enable = true;
      } config;
      image = {
        inherit (image) name outputName;
      };
      user = {
        name = userName;
        ssh = {
          inherit identityFile nixIdentityFile;
        };
        inherit authorizedKeys;
      };
      network = {
        inherit address localDomainApexIp nameservers;
      }
      // (
        if failoverPeer == null then
          { }
        else
          {
            failoverPeer = failoverPeer // {
              probeDomains = localDns.secureDeployProbeDomains;
            };
          }
      );
      nixos.imports = resolvedNixosImports;
      inventory = aarch64Helpers.mkAarch64Inventory {
        inherit userName identityFile nixIdentityFile;
        deployRemoteMethod = "secure";
        secureDeploy = {
          peerName = securePeer.name;
          peerIp = securePeer.ip;
          probeDomains = localDns.secureDeployProbeDomains;
        };
        extraInventory = {
          inherit serviceRoles;
        };
        outputs =
          aarch64Helpers.mkAarch64Outputs {
            name = outputName;
            inherit configuration;
          }
          ++ common.mkImageInventoryOutputs image
          ++ common.mkBootstrapInventoryOutputs bootstrap;
      };
    }
    // (if startKeaOnBoot == null then { } else { inherit startKeaOnBoot; });
}
