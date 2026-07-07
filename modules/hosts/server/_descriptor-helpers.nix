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
  mkServerDescriptor =
    {
      name,
      hostName ? name,
      outputName,
      hostModule,
      identityFile,
      nixIdentityFile,
      localDnsRecords ? [ ],
      config ? { },
      userName ? "sam",
      authorizedKeys ? { },
      systemType ? null,
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
        localDnsRecords
        authorizedKeys
        userName
        systemType
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
      defaultHomeImports = lib.optional (userName == "sam") hostModules.homeManager."sam-home-personal";
      defaultSystemType = "system-cli";
      defaultHomeSystemType = null;
      defaultNixosImports = [
        hostModules.nixos."sam-system-cli"
        hostModules.nixos.deploy-defaults
        hostModules.nixos.caddy
        hostModules.nixos."syncthing-server"
        hostModules.nixos.samba
        hostModules.nixos.attic
        hostModules.nixos.apprise
        hostModules.nixos."atuin-server"
        hostModules.nixos.frigate
        hostModules.nixos.immich
        hostModules.nixos."media-server"
        hostModules.nixos.mealie
        hostModules.nixos."monitoring-stack"
        hostModules.nixos.scrutiny
        hostModules.nixos.podman
        hostModules.nixos.ankerctl
        hostModules.nixos."minecraft-server"
        hostModules.nixos."cross-compile"
      ];
      deployRemoteMethod = "switch";
    };
}
