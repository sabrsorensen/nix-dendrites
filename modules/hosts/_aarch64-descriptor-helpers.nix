{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.self.lib)
    mkInventoryDeploy
    mkInventoryHost
    mkInventorySecureDeploy
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
    }:
    mkNixosOutputs {
      system = "aarch64-linux";
      inherit name configuration;
    };

  mkAarch64Inventory =
    {
      outputs,
      deployRemoteMethod,
      userName ? null,
      identityFile ? null,
      nixIdentityFile ? null,
      secureDeploy ? null,
      extraInventory ? { },
    }:
    mkInventoryHost (
      {
        inherit outputs;
        deploy =
          if secureDeploy == null then
            mkInventoryDeploy {
              remoteMethod = deployRemoteMethod;
            }
          else
            mkInventoryDeploy {
              remoteMethod = deployRemoteMethod;
              secure = mkInventorySecureDeploy secureDeploy;
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
      // extraInventory
    );
}
