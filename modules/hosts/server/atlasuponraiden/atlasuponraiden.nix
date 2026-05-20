{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.AtlasUponRaiden = {
    imports = with inputs.self.modules.nixos; [
      samCli
      ./_atlas/hardware.nix
      ./_atlas/filesystem.nix
      ./_atlas/network.nix
      ./_atlas/users/sam.nix
      ./_atlas/immich.nix
      ./_atlas/docker.nix
      ./_atlas/nix.nix
      (import ./_atlas/syncthing.nix { inherit inputs; })
      (import ./_atlas/nix-remote.nix { inherit inputs lib; })
      (import ./_atlas/home-manager-config.nix { inherit inputs lib; })
      samba
      ./_atlas/samba.nix
      system-cli
      systemd-boot
      disko
      virtualisation
      cross-compile
      nix-index
      caddy
      immich
      #mealie
      media-server
      scrutiny
      syncthing-server
    ];
  };

  flake.modules.homeManager.AtlasUponRaiden = import ./_atlas/home-manager.nix { inherit inputs; };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "AtlasUponRaiden";
}
