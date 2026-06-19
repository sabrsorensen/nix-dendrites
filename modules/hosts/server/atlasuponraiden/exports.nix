{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.atlasUponRaidenHostHome = import ./_atlas/home-manager.nix {
    inherit inputs;
  };

  flake.modules.nixos = {
    atlasUponRaiden = {
      imports = [
        ./_atlas/hardware.nix
        ./_atlas/filesystem.nix
        ./_atlas/network.nix
        ./_atlas/users/sam.nix
        ./_atlas/immich.nix
        ./_atlas/media.nix
        (import ./_atlas/syncthing.nix { inherit inputs; })
        (import ./_atlas/nix-remote.nix { inherit inputs lib; })
        ./_atlas/samba.nix
      ];
    };
  };
}
