{
  inputs,
  lib,
  ...
}:
let
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib; };
  hostModules = inputs.self.modules;
in
descriptorHelpers.mkWorkstationDescriptor {
  name = "Kamino";
  identityFile = "~/.ssh/kamino_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_kamino_id_ed25519";
  homeImports = [ hostModules.homeManager.kaminoHome ];
  hostModule = hostModules.nixos.kamino;
  extraImports = with hostModules.nixos; [
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
