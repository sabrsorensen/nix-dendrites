{
  inputs,
  lib,
  ...
}:
let
  x86Helpers = import ../_x86-descriptor-helpers.nix { inherit inputs lib; };
in
{
  mkWorkstationDescriptor =
    {
      name,
      hostName ? name,
      outputName ? lib.strings.toLower name,
      homeImports ? [ ],
      homeProfileNames ? [ ],
      hostModule,
      identityFile,
      nixIdentityFile,
      userName ? "sam",
      authorizedKeys ? { },
      extraImports ? [ ],
      nixosProfileNames ? [ ],
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
        homeImports
        extraImports
        nixosProfileNames
        enableSystemdBoot
        enableDisko
        bootstrap
        ;
      defaultHomeProfileNames = lib.optional (userName == "sam") "sam-home-personal";
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
      defaultNixosProfileNames = [
        "sam"
        "system-workstation"
      ];
      deployRemoteMethod = "switch";
    };
}
