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
  name = "ZaphodBeeblebrox";
  identityFile = "~/.ssh/zaphod_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_zaphodbeeblebrox_id_ed25519";
  homeImports = [ hostModules.homeManager.zaphodBeeblebroxHostHome ];
  hostModule = hostModules.nixos.zaphodBeeblebrox;
  config.features = {
    bluetooth = true;
    flatpak = true;
    nvidia = true;
    steam = true;
    wine = true;
  };
  extraImports = with hostModules.nixos; [
    system-desktop
    systemd-boot
    disko
  ];
}
