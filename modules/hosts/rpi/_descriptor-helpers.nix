{
  inputs,
  lib,
  network,
}:
let
  aarch64Helpers = import ../_aarch64-descriptor-helpers.nix { inherit inputs lib; };
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
      outputName,
      bootstrap ? null,
    }:
    {
      kind = "static";
      inherit
        bootstrap
        config
        localDnsRecords
        name
        outputName
        ;
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
      outputName,
      bootstrap ? null,
    }:
    {
      kind = "dhcp";
      inherit
        bootstrap
        config
        name
        outputName
        ;
      image = {
        name = imageName;
        outputName = imageOutputName;
      };
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
          ++ builtins.map (output: output // { buildProduct = "sdImage"; }) (
            aarch64Helpers.mkAarch64Outputs {
              name = imageOutputName;
              configuration = imageName;
            }
          )
          ++ lib.optionals (bootstrap != null) (
            aarch64Helpers.mkAarch64Outputs {
              name = bootstrap.outputName;
              configuration = bootstrap.configurationName;
            }
            ++ builtins.map (output: output // { buildProduct = "sdImage"; }) (
              aarch64Helpers.mkAarch64Outputs {
                name = bootstrap.imageOutputName;
                configuration = bootstrap.imageName;
              }
            )
          );
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
      bootstrap ? null,
    }:
    {
      kind = "service";
      inherit
        bootstrap
        config
        name
        outputName
        ;
      image = {
        name = imageName;
        outputName = imageOutputName;
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
      nixos.imports = with inputs.self.modules.nixos; [
        blocky
        dhcp-coredns
      ];
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
          ++ builtins.map (output: output // { buildProduct = "sdImage"; }) (
            aarch64Helpers.mkAarch64Outputs {
              name = imageOutputName;
              configuration = imageName;
            }
          )
          ++ lib.optionals (bootstrap != null) (
            aarch64Helpers.mkAarch64Outputs {
              name = bootstrap.outputName;
              configuration = bootstrap.configurationName;
            }
            ++ builtins.map (output: output // { buildProduct = "sdImage"; }) (
              aarch64Helpers.mkAarch64Outputs {
                name = bootstrap.imageOutputName;
                configuration = bootstrap.imageName;
              }
            )
          );
      };
    }
    // (if startKeaOnBoot == null then { } else { inherit startKeaOnBoot; });
}
