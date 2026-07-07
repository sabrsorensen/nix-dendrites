{
  inputs,
  lib,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
  x86Helpers = import ../_x86-descriptor-helpers.nix { inherit inputs lib; };
in
{
  mkWslDescriptor =
    {
      name,
      hostName ? name,
      outputName,
      hostModule,
      systemType ? null,
      config ? { },
    }:
    x86Helpers.mkProfiledX86Descriptor {
      inherit
        name
        hostName
        outputName
        hostModule
        systemType
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
      defaultHomeImports = [
        hm."sam-home-work"
        hm."sam-home-work-wsl"
      ];
      deployRemoteMethod = null;
    };
}
