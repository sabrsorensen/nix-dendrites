{
  inputs,
  ...
}:
{
  flake.modules.nixos.AtlasUponRaiden = {
    imports = with inputs.self.modules.nixos; [
      sam
      ./_atlas/hardware.nix
      ./_atlas/filesystem.nix
      ./_atlas/network.nix
      ./_atlas/users/sam.nix
      ./_atlas/docker.nix
      ./_atlas/samba.nix
      system-cli
      systemd-boot
      disko
      virtualisation
    ];

    home-manager.users.sam = {
      imports = [
        inputs.self.modules.homeManager.AtlasUponRaiden
      ];
    };
  };

  flake.modules.homeManager.AtlasUponRaiden = {
    imports = with inputs.self.modules.homeManager; [
    ];
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "AtlasUponRaiden";
}
