{
  inputs,
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
      samba
      ./_atlas/samba.nix
      system-cli
      systemd-boot
      disko
      virtualisation
      cross-compile
    ];

    home-manager.users.sam = {
      imports = [
        inputs.self.modules.homeManager.AtlasUponRaiden
      ];
    };
    users.users.nix-remote = {
      openssh.authorizedKeys.keyFiles = [
        "${inputs.nix-secrets}/ssh-keys/zaphod_atlas_nix.pub"
      ];
    };
  };

  flake.modules.homeManager.AtlasUponRaiden = {
    imports = with inputs.self.modules.homeManager; [
    ];
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "AtlasUponRaiden";
}
