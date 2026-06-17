{
  inputs,
  lib,
  ...
}:
let
  server = import ./_public.nix { inherit inputs lib; };
  hostModules = inputs.self.modules.nixos;
  hostData = import ./atlasuponraiden/_atlas/host-data.nix { inherit inputs; };
  descriptors = [
    ({
      name = "AtlasUponRaiden";
      nixos.imports = [
        hostModules.samCli
        hostModules.atlasUponRaidenHardware
        hostModules.atlasUponRaidenFilesystem
        hostModules.atlasUponRaidenNetwork
        hostModules.atlasUponRaidenUserSam
        hostModules.atlasUponRaidenImmich
        hostModules.atlasUponRaidenMedia
        hostModules.atlasUponRaidenSyncthing
        hostModules.atlasUponRaidenNixRemote
        hostModules.samba
        hostModules.atlasUponRaidenSamba
        hostModules.deploy-defaults
        hostModules.system-cli
        hostModules.systemd-boot
        hostModules.disko
        hostModules.podman
        hostModules.cross-compile
        hostModules.nix-index
        hostModules.caddy
        hostModules.apprise
        hostModules.ankerctl
        hostModules.immich
        hostModules.mealie
        hostModules.media-server
        hostModules.minecraft-server
        hostModules.demlo
        hostModules.scrutiny
        hostModules.syncthing-server
      ];
    }
    // hostData)
  ];
in
{
  imports = [ ./exports.nix ] ++ map server.mkRegisteredHost descriptors;
}
