{
  inputs,
  lib,
  ...
}:
let
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib; };
in
descriptorHelpers.mkWorkstationDescriptor {
  name = "ZaphodBeeblebrox";
  identityFile = "~/.ssh/zaphod_id_ed25519";
  nixIdentityFile = "~/.ssh/nix_zaphodbeeblebrox_id_ed25519";
  hostModule = inputs.self.modules.nixos.zaphodBeeblebrox;
  config.roles.builder = true;
  config.features = {
    bitwarden = true;
    bluetooth = true;
    containers = true;
    deskflow = true;
    flatpak = true;
    minecraft = true;
    nvidia = true;
    noson = true;
    office = true;
    steam = true;
    threedprinter = true;
    wine = true;
    zsa = true;
  };
  enableSystemdBoot = true;
  enableDisko = true;
}
