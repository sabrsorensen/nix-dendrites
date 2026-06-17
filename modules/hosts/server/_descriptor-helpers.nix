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
      outputName,
      hostModule,
      identityFile,
      nixIdentityFile,
      homeImports ? [ ],
      localDnsRecords ? [ ],
      config ? { },
      userName ? "sam",
      extraImports ? [ ],
      builder ? null,
      extraInventory ? { },
    }:
    x86Helpers.mkX86Descriptor {
      inherit
        name
        config
        localDnsRecords
        ;
      user = {
        name = userName;
        ssh = {
          inherit identityFile nixIdentityFile;
        };
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
        deployRemoteMethod = "switch";
      };
    };
}
