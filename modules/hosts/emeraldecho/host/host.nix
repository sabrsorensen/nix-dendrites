{
  config,
  inputs,
  lib,
  ...
}:
let
  payload = import ./_content.nix { inherit inputs lib; };
in
{
  flake.homeConfigurations.emeraldecho-steamos = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
    modules = [ payload.steamosLibraryModule ];
  };
  flake.nixosConfigurations.emeraldecho = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.singleBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.singleBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootInstallerModule
      (payload.installerIso true)
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.dualBootInstallerModule
      (payload.installerIso true)
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.singleBootInstallerModule
      (payload.installerIso false)
    ];
  };
}
