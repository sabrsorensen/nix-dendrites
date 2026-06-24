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
  hostModule = hostModules.nixos.zaphodBeeblebrox;
  config.features = {
    bluetooth = true;
    containers = true;
    deskflow = true;
    flatpak = true;
    minecraft = true;
    nvidia = true;
    steam = true;
    threedprinter = true;
    wine = true;
  };
  enableSystemdBoot = true;
  enableDisko = true;
}
