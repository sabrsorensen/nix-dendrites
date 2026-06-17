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
  mkWorkstationDescriptor =
    {
      name,
      outputName ? lib.strings.toLower name,
      homeImports,
      hostModule,
      identityFile,
      nixIdentityFile,
      userName ? "sam",
      extraImports ? [ ],
      config ? { },
    }:
    x86Helpers.mkX86Descriptor {
      inherit
        name
        homeImports
        ;
      config = {
        primaryInteractiveUser = userName;
        roles = {
          workstation = true;
          desktop = true;
        };
        deploy = {
          canDeployRemotely = true;
          enableRemoteUser = true;
          sleepy = true;
        };
        ssh.enableNixBlocks = true;
        syncthing = {
          mode = "home";
          hasTray = true;
        };
      }
      // config;
      user = {
        name = userName;
        ssh = {
          inherit identityFile nixIdentityFile;
        };
      };
      nixosImports = [
        hostModules.nixos.sam
        hostModule
      ] ++ extraImports;
      inventory = x86Helpers.mkX86Inventory {
        inherit
          name
          outputName
          userName
          identityFile
          nixIdentityFile
          ;
        deployRemoteMethod = "switch";
      };
    };
}
