{
  inputs,
  lib,
  ...
}:
let
  wsl = import ./_public.nix { inherit inputs lib; };
  descriptors = [
    {
      name = "NixOS-WSL";
      nixos.imports = [
        inputs.self.modules.nixos.nixos-wsl-system
        inputs.self.modules.nixos."work-dev"
        inputs.self.modules.nixos.nixos-wsl-user
        wsl.nixosWslHomeDefaults
      ];
      home.module = inputs.self.modules.homeManager.nixos-wsl;
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
      inventory = inputs.self.lib.mkInventoryHost {
        outputs = inputs.self.lib.mkNixosOutputs {
          system = "x86_64-linux";
          name = "nixos-wsl";
          configuration = "NixOS-WSL";
        };
      };
    }
  ];
in
{
  imports = [ ./exports.nix ] ++ map wsl.mkRegisteredHost descriptors;
}
