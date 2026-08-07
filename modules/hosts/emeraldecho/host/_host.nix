{ inputs, lib, ... }:
let
  hostPkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  steamosLibraryModule = import ./_host-steamos-library.nix;
  hostModule = import ./_host-facts.nix {
    inherit hostPkgs inputs;
  };
  dualBootModule = lib.recursiveUpdate hostModule {
    my.host.tags = [ "steamdeck-dualboot" ];
  };
  dualBootBootstrapModule = import ./_host-bootstrap.nix {
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
  singleBootBootstrapModule = import ./_host-bootstrap.nix {
    inherit lib;
    baseModule = singleBootModule;
    finalConfigName = "emeraldecho-singleboot";
    tags = [
      "steamdeck-singleboot"
      "bootstrap"
    ];
  };
  installer = import ./_host-installer.nix {
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
