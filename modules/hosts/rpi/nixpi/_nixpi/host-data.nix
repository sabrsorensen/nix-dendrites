{
  inputs,
  lib,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib network; };
in
descriptorHelpers.mkDhcpDescriptor {
  name = "NixPi";
  outputName = "nixpi";
  imageName = "NixPiImage";
  imageOutputName = "nixpi-image";
  hostName = "nixpi";
  configuration = "NixPi";
  bootstrap = {
    configurationName = "NixPiBootstrap";
    outputName = "nixpi-bootstrap";
    imageName = "NixPiBootstrapImage";
    imageOutputName = "nixpi-bootstrap-image";
    finalConfigName = "NixPi";
    authorizedKeyPaths = [ "zaphodbeeblebrox/kamino" ];
    user.extraGroups = [
      "wheel"
      "video"
    ];
    nixos.imports = [ ];
  };
}
