{
  inputs,
  lib,
  ...
}:
let
  hostModules = inputs.self.modules;
  x86Helpers = import ../common/descriptors/_x86.nix { inherit inputs lib; };
in
{
  mkWorkstationDescriptor =
    {
      name,
      hostName ? name,
      outputName ? lib.strings.toLower name,
      hostModule,
      identityFile,
      nixIdentityFile,
      userName ? "sam",
      authorizedKeys ? { },
      systemType ? null,
      enableSystemdBoot ? false,
      enableDisko ? false,
      config ? { },
      bootstrap ? null,
    }:
    x86Helpers.mkProfiledX86Descriptor {
      inherit
        name
        hostName
        outputName
        hostModule
        identityFile
        nixIdentityFile
        userName
        authorizedKeys
        systemType
        enableSystemdBoot
        enableDisko
        bootstrap
        ;
      defaultHomeImports = lib.optional (userName == "sam") hostModules.homeManager."sam-home-personal";
      config = lib.recursiveUpdate {
        primaryInteractiveUser = userName;
        formFactor = "laptop";
        roles = {
          workstation = true;
          desktop = true;
        };
        features = {
          firmware = true;
          gui = true;
          nix-ld = true;
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
      } config;
      defaultNixosImports = [ hostModules.nixos.sam ];
      defaultSystemType = "system-workstation";
      defaultHomeSystemType = "system-workstation";
      deployRemoteMethod = "switch";
    };
}
