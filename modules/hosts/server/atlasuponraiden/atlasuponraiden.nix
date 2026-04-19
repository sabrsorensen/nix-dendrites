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
      ./_atlas/docker.nix
      (import ./_atlas/nix-remote.nix { inherit inputs lib; })
      samba
      ./_atlas/samba.nix
      system-cli
      systemd-boot
      disko
      virtualisation
      cross-compile
      syncthing-server
      {
        imports = [
          # Universal syncthing config that works in both NixOS and Home Manager contexts
          "${inputs.nix-secrets}/modules/sam-syncthing-universal.nix"
        ];

        # Enable server-mode syncthing for AtlasUponRaiden
        my.syncthing.enable = true;
        my.syncthing.serverUser = "sam";
      }
      {
        home-manager.users.sam = {
          imports = [
            inputs.self.modules.homeManager.AtlasUponRaiden
          ];
          # Force disable Home Manager syncthing to avoid conflicts with NixOS service
          my.syncthing.enable = lib.mkForce false;
        };
      }
    ];
  };

  flake.modules.homeManager.AtlasUponRaiden = import ./_atlas/home-manager.nix { };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "AtlasUponRaiden";
}
