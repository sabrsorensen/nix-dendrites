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
  hostModule = hostModules.nixos.kamino;
  config.roles.builder = true;
  config.features = {
    containers = true;
    deskflow = true;
    flatpak = true;
    minecraft = true;
    nvidia = true;
    steam = true;
    threedprinter = true;
    wine = true;
    zsa = true;
  };
  enableSystemdBoot = true;
  bootstrap = {
    configurationName = "KaminoBootstrap";
    outputName = "kamino-bootstrap";
    finalConfigName = "Kamino";
    authorizedKeyPaths = [ "zaphodbeeblebrox/kamino" ];
    nixos.imports = [ hostModules.nixos.kaminoBootstrap ];
    user.extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
}
