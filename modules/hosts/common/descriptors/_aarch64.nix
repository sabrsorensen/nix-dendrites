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
  mkAarch64Outputs =
    {
      name,
      configuration,
      collections ? [ "checks" ],
    }:
    mkNixosOutputs {
      system = "aarch64-linux";
      inherit
        name
        configuration
        collections
        ;
    };

  mkAarch64Inventory =
    {
      outputs,
      userName ? null,
      identityFile ? null,
      nixIdentityFile ? null,
      deployRemoteMethod ? null,
      secureDeploy ? null,
      extraInventory ? { },
    }:
    mkInventoryHost (
      {
        inherit outputs;
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
          secure = secureDeploy;
        };
      }
      // extraInventory
    );
}
