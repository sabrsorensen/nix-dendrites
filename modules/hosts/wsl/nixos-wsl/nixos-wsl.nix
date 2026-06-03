{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos."NixOS-WSL" = {
    imports = [
      (import ./_nixos-wsl/system.nix { inherit inputs; })
      inputs.self.modules.nixos."work-dev"
      ./_nixos-wsl/user.nix
      (import ./_nixos-wsl/home-defaults.nix { inherit inputs lib; })
    ];

    my.host = {
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
  };

  flake.modules.homeManager."NixOS-WSL" = import ./_nixos-wsl/home-manager.nix { inherit inputs; };

  flake.lib.hostInventory."NixOS-WSL" = inputs.self.lib.mkInventoryHost {
    outputs = inputs.self.lib.mkNixosOutputs {
      system = "x86_64-linux";
      name = "nixos-wsl";
      configuration = "NixOS-WSL";
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "NixOS-WSL";
}
