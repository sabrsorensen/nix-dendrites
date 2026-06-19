{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.self.lib)
    mkInventoryDeploy
    mkInventoryHost
    mkInventorySsh
    mkInventorySshBase
    mkInventorySshNix
    mkNixosOutputs
    ;
in
{
  mkX86Inventory =
    {
      name,
      outputName ? lib.strings.toLower name,
      outputs ? null,
      userName ? null,
      identityFile ? null,
      nixIdentityFile ? null,
      deployRemoteMethod ? null,
      builder ? null,
      extraInventory ? { },
    }:
    mkInventoryHost (
      {
        outputs =
          if outputs != null then
            outputs
          else
            mkNixosOutputs {
              system = "x86_64-linux";
              name = outputName;
              configuration = name;
            };
      }
      // lib.optionalAttrs (userName != null && identityFile != null && nixIdentityFile != null) {
        ssh = mkInventorySsh {
          base = mkInventorySshBase {
            user = userName;
            inherit identityFile;
          };
          nix = mkInventorySshNix {
            identityFile = nixIdentityFile;
          };
        };
      }
      // lib.optionalAttrs (deployRemoteMethod != null) {
        deploy = mkInventoryDeploy {
          remoteMethod = deployRemoteMethod;
        };
      }
      // lib.optionalAttrs (builder != null) {
        inherit builder;
      }
      // extraInventory
    );

  mkX86Descriptor =
    {
      name,
      hostName ? name,
      homeImports ? [ ],
      nixosImports,
      config ? { },
      inventory,
      user ? null,
      localDnsRecords ? [ ],
      bootstrap ? null,
    }:
    {
      inherit
        name
        hostName
        config
        inventory
        bootstrap
        ;
      home.imports = homeImports;
      nixos.imports = nixosImports;
    }
    // lib.optionalAttrs (user != null) {
      inherit user;
    }
    // lib.optionalAttrs (localDnsRecords != [ ]) {
      inherit localDnsRecords;
    };
}
