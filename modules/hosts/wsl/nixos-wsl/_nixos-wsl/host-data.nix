{
  inputs,
  lib,
  ...
}:
let
  descriptorHelpers = import ../../_descriptor-helpers.nix { inherit inputs lib; };
  hostModules = inputs.self.modules;
in
descriptorHelpers.mkWslDescriptor {
  name = "NixOS-WSL";
  outputName = "nixos-wsl";
  homeImports = [ hostModules.homeManager.nixosWslHome ];
  hostModule = hostModules.nixos.nixosWsl;
  extraImports = [
    hostModules.nixos."work-dev"
    (import ./home-defaults.nix { inherit inputs lib; })
  ];
  config = {
    primaryInteractiveUser = lib.mkDefault "sam";
    roles = {
      workstation = true;
      wsl = true;
    };
    deploy = {
      canDeployRemotely = false;
      sleepy = false;
    };
    syncthing.mode = "disabled";
  };
}
