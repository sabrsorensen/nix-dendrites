{
  inputs,
  lib,
  ...
}:
let
  shared = import ./_emeraldecho/shared.nix { inherit inputs; };
  mkEmeraldSystemModule = import ./_emeraldecho/system-module.nix {
    inherit inputs lib shared;
  };
  mkEmeraldBootstrapModule = import ./_emeraldecho/bootstrap-module.nix {
    inherit inputs lib shared;
  };
  mkEmeraldInstallerModule = import ./_emeraldecho/installer-module.nix {
    inherit inputs lib shared;
  };
in
{
  flake.modules.nixos.EmeraldEcho = mkEmeraldSystemModule "dual";
  flake.modules.nixos.EmeraldEchoDualBoot = mkEmeraldSystemModule "dual";
  flake.modules.nixos.EmeraldEchoSingleBoot = mkEmeraldSystemModule "single";

  flake.modules.nixos.EmeraldEchoBootstrap = mkEmeraldBootstrapModule "dual";
  flake.modules.nixos.EmeraldEchoDualBootBootstrap = mkEmeraldBootstrapModule "dual";
  flake.modules.nixos.EmeraldEchoSingleBootBootstrap = mkEmeraldBootstrapModule "single";

  flake.modules.nixos.EmeraldEchoInstaller = mkEmeraldInstallerModule "dual";
  flake.modules.nixos.EmeraldEchoDualBootInstaller = mkEmeraldInstallerModule "dual";
  flake.modules.nixos.EmeraldEchoSingleBootInstaller = mkEmeraldInstallerModule "single";

  flake.modules.homeManager.EmeraldEcho = import ./_emeraldecho/home-module.nix { inherit inputs; };

  flake.homeConfigurations."deck@EmeraldEcho" = import ./_emeraldecho/home-configuration.nix {
    inherit inputs shared;
  };

  flake.nixosConfigurations = import ./_emeraldecho/nixos-configurations.nix {
    inherit inputs lib;
  };
}
