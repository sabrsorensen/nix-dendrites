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
      nixosProfileNames ? [ ],
      outputName,
      extraImports ? [ ],
      bootstrap ? null,
    }:
    let
      resolvedNixosImports =
        extraImports ++ map (profileName: inputs.self.modules.nixos.${profileName}) nixosProfileNames;
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
      nixosProfileNames ? [ ],
      outputName,
      extraImports ? [ ],
      bootstrap ? null,
    }:
    let
      resolvedNixosImports =
        extraImports ++ map (profileName: inputs.self.modules.nixos.${profileName}) nixosProfileNames;
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
      nixosProfileNames ? [ ],
      extraImports ? [ ],
      bootstrap ? null,
    }:
    let
      resolvedNixosImports =
        (with inputs.self.modules.nixos; [
          blocky
          dhcp-coredns
        ])
        ++ extraImports
        ++ map (profileName: inputs.self.modules.nixos.${profileName}) nixosProfileNames;
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
