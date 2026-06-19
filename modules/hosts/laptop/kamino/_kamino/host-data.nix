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
  homeImports = [ hostModules.homeManager.kaminoHostHome ];
  hostModule = hostModules.nixos.kamino;
  config.features = {
    flatpak = true;
    nvidia = true;
    wine = true;
  };
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
  extraImports = with hostModules.nixos; [
    system-desktop
    systemd-boot
  ];
}
