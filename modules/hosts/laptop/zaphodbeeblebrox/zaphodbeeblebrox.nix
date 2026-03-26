{
  inputs,
  ...
}:
{
  flake.modules.nixos.ZaphodBeeblebrox = {
    imports = with inputs.self.modules.nixos; [
      sam
      ./_zaphod/hardware.nix
      ./_zaphod/filesystem.nix
      ./_zaphod/network.nix
      ./_zaphod/users/sam.nix
      system-desktop
      systemd-boot
      disko
      bluetooth
      kde
      nvidia
      xserver
    ];

    home-manager.users.sam = {
      imports = [
        inputs.self.modules.homeManager.ZaphodBeeblebrox
      ];
    };
  };

  flake.modules.homeManager.ZaphodBeeblebrox = {
    imports = with inputs.self.modules.homeManager; [
      firefox
      konsole
      mcp
      mcp-personal
      vscode
    ];
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "ZaphodBeeblebrox";
}
