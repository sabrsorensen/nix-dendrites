{
  inputs,
  lib,
  ...
}:
let
  x86Helpers = import ../_x86-descriptor-helpers.nix { inherit inputs lib; };
  hostModules = inputs.self.modules;
in
{
  mkServerDescriptor =
    {
      name,
      hostName ? name,
      outputName,
      hostModule,
      identityFile,
      nixIdentityFile,
      homeImports ? [ ],
      localDnsRecords ? [ ],
      config ? { },
      userName ? "sam",
      authorizedKeys ? { },
      extraImports ? [ ],
      builder ? null,
      extraInventory ? { },
      bootstrap ? null,
    }:
    x86Helpers.mkX86Descriptor {
      inherit
        name
        hostName
        localDnsRecords
        bootstrap
        ;
      config = lib.recursiveUpdate {
        formFactor = "server";
        roles.server = true;
      } config;
      user = {
        name = userName;
        ssh = {
          inherit identityFile nixIdentityFile;
        };
      }
      // lib.optionalAttrs (authorizedKeys != { }) {
        inherit authorizedKeys;
      };
      inherit homeImports;
      nixosImports = [
        hostModules.nixos.samCli
        hostModule
      ]
      ++ extraImports;
      inventory = x86Helpers.mkX86Inventory {
        inherit
          name
          outputName
          userName
          identityFile
          nixIdentityFile
          builder
          extraInventory
          ;
        outputs =
          inputs.self.lib.mkNixosOutputs {
            system = "x86_64-linux";
            name = outputName;
            configuration = name;
          }
          ++ lib.optionals (bootstrap != null) (
            inputs.self.lib.mkNixosOutputs {
              system = "x86_64-linux";
              name = bootstrap.outputName;
              configuration = bootstrap.configurationName;
            }
          );
        deployRemoteMethod = "switch";
      };
    };
}
