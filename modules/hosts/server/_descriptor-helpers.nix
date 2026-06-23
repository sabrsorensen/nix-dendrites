{
  inputs,
  lib,
  ...
}:
let
  x86Helpers = import ../_x86-descriptor-helpers.nix { inherit inputs lib; };
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
      homeProfileNames ? [ ],
      localDnsRecords ? [ ],
      config ? { },
      userName ? "sam",
      authorizedKeys ? { },
      extraImports ? [ ],
      nixosProfileNames ? [ ],
      enableSystemdBoot ? false,
      enableDisko ? false,
      builder ? null,
      extraInventory ? { },
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
        homeImports
        homeProfileNames
        localDnsRecords
        authorizedKeys
        userName
        extraImports
        nixosProfileNames
        enableSystemdBoot
        enableDisko
        builder
        extraInventory
        bootstrap
        ;
      config = lib.recursiveUpdate {
        formFactor = "server";
        roles.server = true;
        features = {
          firmware = true;
          nix-ld = true;
        };
      } config;
      defaultHomeProfileNames = lib.optional (userName == "sam") "sam-home-personal";
      defaultNixosProfileNames = [
        "sam-system-cli"
        "deploy-defaults"
        "system-cli"
        "caddy"
        "syncthing-server"
        "samba"
        "apprise"
        "atuin-server"
        "immich"
        "mealie"
        "scrutiny"
        "podman"
        "ankerctl"
        "minecraft-server"
        "cross-compile"
        "media-server"
      ];
      deployRemoteMethod = "switch";
    };
}
