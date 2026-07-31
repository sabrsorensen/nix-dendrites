{ inputs, lib, ... }:
let
  hostPkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  steamosLibraryModule = import ./_steamos-library-content.nix;
  hostModule = import ./_host-content.nix {
    inherit hostPkgs inputs;
  };
  dualBootModule = lib.recursiveUpdate hostModule {
    my.host.tags = [ "steamdeck-dualboot" ];
  };
  dualBootBootstrapModule = import ./_bootstrap-content.nix {
    inherit lib;
    baseModule = dualBootModule;
    finalConfigName = "emeraldecho-dualboot";
    tags = [
      "steamdeck-dualboot"
      "bootstrap"
    ];
  };
  singleBootModule = lib.recursiveUpdate hostModule {
    my.host.tags = [ "steamdeck-singleboot" ];
  };
  singleBootBootstrapModule = import ./_bootstrap-content.nix {
    inherit lib;
    baseModule = singleBootModule;
    finalConfigName = "emeraldecho-singleboot";
    tags = [
      "steamdeck-singleboot"
      "bootstrap"
    ];
  };
  installer = import ./_installer-content.nix {
    inherit inputs lib;
  };
  dualBootInstallerModule = installer.mkInstallerModule {
    baseModule = dualBootModule;
    isDualBoot = true;
  };
  singleBootInstallerModule = installer.mkInstallerModule {
    baseModule = singleBootModule;
    isDualBoot = false;
  };
in
{
  inherit
    steamosLibraryModule
    dualBootModule
    dualBootBootstrapModule
    singleBootModule
    singleBootBootstrapModule
    dualBootInstallerModule
    singleBootInstallerModule
    ;
  inherit (installer) installerIso;
}
