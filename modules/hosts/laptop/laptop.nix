{
  inputs,
  lib,
  ...
}:
let
  laptop = import ./_public.nix { inherit inputs lib; };
  hostModules = inputs.self.modules;
  primaryInteractiveUser = "sam";

  workstationDescriptors = [
    {
      name = "Kamino";
      user = {
        name = primaryInteractiveUser;
        ssh = {
          identityFile = "~/.ssh/kamino_id_ed25519";
          nixIdentityFile = "~/.ssh/nix_kamino_id_ed25519";
        };
      };
      home.module = hostModules.homeManager.kaminoHome;
      nixos.imports = with hostModules.nixos; [
        sam
        kaminoHardware
        kaminoFilesystem
        kaminoNetwork
        kaminoBoot
        kaminoDesktop
        kaminoPackages
        kaminoUserSam
        system-desktop
        systemd-boot
        flatpak
        nix-index
        nvidia
        kde
        wine
        xserver
      ];
    }
    {
      name = "ZaphodBeeblebrox";
      user = {
        name = primaryInteractiveUser;
        ssh = {
          identityFile = "~/.ssh/zaphod_id_ed25519";
          nixIdentityFile = "~/.ssh/nix_zaphodbeeblebrox_id_ed25519";
        };
      };
      home.module = hostModules.homeManager.zaphodBeeblebroxHome;
      nixos.imports = with hostModules.nixos; [
        sam
        zaphodBeeblebroxHardware
        zaphodBeeblebroxFilesystem
        zaphodBeeblebroxNetwork
        zaphodBeeblebroxUserSam
        system-desktop
        systemd-boot
        disko
        bluetooth
        flatpak
        nix-index
        kde
        nvidia
        wine
        xserver
      ];
    }
  ];
in
{
  imports = [ ./exports.nix ] ++ map laptop.mkRegisteredHost workstationDescriptors;
}
