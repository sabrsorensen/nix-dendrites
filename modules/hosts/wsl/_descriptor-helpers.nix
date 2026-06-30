{
  inputs,
  lib,
  ...
}:
let
  x86Helpers = import ../_x86-descriptor-helpers.nix { inherit inputs lib; };
in
{
  mkWslDescriptor =
    {
      name,
      hostName ? name,
      outputName,
      homeImports ? [ ],
      homeProfileNames ? [ ],
      hostModule,
      extraImports ? [ ],
      nixosProfileNames ? [ ],
      config ? { },
    }:
    x86Helpers.mkProfiledX86Descriptor {
      inherit
        name
        hostName
        homeImports
        homeProfileNames
        outputName
        hostModule
        extraImports
        nixosProfileNames
        ;
      config = lib.recursiveUpdate {
        primaryInteractiveUser = lib.mkDefault "sam";
        tags = [ "wsl" ];
        roles = {
          workstation = true;
          wsl = true;
        };
        features.nix-ld = true;
        deploy = {
          canDeployRemotely = false;
          sleepy = false;
        };
        syncthing.mode = "disabled";
      } config;
      deployRemoteMethod = null;
    };
}
