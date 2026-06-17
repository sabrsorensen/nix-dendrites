{
  inputs,
  network,
}:
let
  inherit (inputs.self.lib)
    localDns
    mkInventoryDeploy
    mkInventoryHost
    mkInventorySecureDeploy
    mkInventorySsh
    mkInventorySshBase
    mkInventorySshNix
    mkNixosOutputs
    ;
in
rec {
  mkStaticDescriptor =
    {
      address,
      configuration,
      hostName,
      localDnsRecords ? [ ],
      name,
      outputName,
    }:
    {
      kind = "static";
      inherit localDnsRecords name outputName;
      network = {
        inherit address hostName;
      };
      inventory = mkInventoryHost {
        deploy = mkInventoryDeploy {
          remoteMethod = "switch";
        };
        outputs = mkNixosOutputs {
          system = "aarch64-linux";
          name = outputName;
          inherit configuration;
        };
      };
    };

  mkDhcpDescriptor =
    {
      configuration,
      hostName,
      imageName,
      imageOutputName,
      name,
      outputName,
    }:
    {
      kind = "static";
      inherit name outputName;
      image = {
        name = imageName;
        outputName = imageOutputName;
      };
      network = {
        inherit hostName;
        address = null;
        dhcp = true;
      };
      inventory = mkInventoryHost {
        deploy = mkInventoryDeploy {
          remoteMethod = "switch";
        };
        outputs =
          mkNixosOutputs {
            system = "aarch64-linux";
            name = outputName;
            inherit configuration;
          }
          ++ mkNixosOutputs {
            system = "aarch64-linux";
            name = imageOutputName;
            configuration = imageName;
            buildProduct = "sdImage";
          };
      };
    };

  mkServiceDescriptor =
    {
      address,
      authorizedKeys,
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
    }:
    {
      kind = "service";
      inherit name outputName;
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
      inventory = mkInventoryHost {
        ssh = mkInventorySsh {
          base = mkInventorySshBase {
            user = userName;
            inherit identityFile;
          };
          nix = mkInventorySshNix {
            identityFile = nixIdentityFile;
          };
        };
        inherit serviceRoles;
        deploy = mkInventoryDeploy {
          remoteMethod = "secure";
          secure = mkInventorySecureDeploy {
            peerName = securePeer.name;
            peerIp = securePeer.ip;
            probeDomains = localDns.secureDeployProbeDomains;
          };
        };
        outputs =
          mkNixosOutputs {
            system = "aarch64-linux";
            name = outputName;
            inherit configuration;
          }
          ++ mkNixosOutputs {
            system = "aarch64-linux";
            name = imageOutputName;
            configuration = imageName;
            buildProduct = "sdImage";
          };
      };
    }
    // (
      if startKeaOnBoot == null then
        { }
      else
        { inherit startKeaOnBoot; }
    );
}
