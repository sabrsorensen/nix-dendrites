{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos = {
    atlasUponRaidenHardware = ./_atlas/hardware.nix;
    atlasUponRaidenFilesystem = ./_atlas/filesystem.nix;
    atlasUponRaidenNetwork = ./_atlas/network.nix;
    atlasUponRaidenUserSam = ./_atlas/users/sam.nix;
    atlasUponRaidenImmich = ./_atlas/immich.nix;
    atlasUponRaidenMedia = ./_atlas/media.nix;
    atlasUponRaidenSyncthing = import ./_atlas/syncthing.nix { inherit inputs; };
    atlasUponRaidenNixRemote = import ./_atlas/nix-remote.nix { inherit inputs lib; };
    atlasUponRaidenSamba = ./_atlas/samba.nix;
  };
}
