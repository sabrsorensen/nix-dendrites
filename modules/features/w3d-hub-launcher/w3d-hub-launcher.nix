{ ... }:
let
  supportedSystem = "x86_64-linux";
in
{
  flake.modules.nixos.w3d-hub-launcher =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.w3dHubLauncher =
        lib.mkEnableOption "the Linux-native W3D Hub game launcher";

      config = lib.mkIf config.my.host.features.w3dHubLauncher {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.system == supportedSystem;
            message = "my.host.features.w3dHubLauncher is only supported on x86_64-linux because upstream ships an x86_64-only prebuilt binary.";
          }
        ];

        environment.systemPackages = lib.optional (pkgs.stdenv.hostPlatform.system == supportedSystem) (
          pkgs.callPackage ./_package.nix { }
        );

        # The launcher runs 32-bit DirectX 9 W3D-engine games through the Wine
        # bundled on its wrapper PATH; those need the 32-bit GPU userspace.
        # Already implied by features.wine / features.steam where present, set
        # here so the feature stands on its own (e.g. on the Steam Deck).
        hardware.graphics.enable32Bit = lib.mkDefault true;

        # The prebuilt binary carries no upstream license.
        my.unfreePackageNames = [ "w3d-hub-linux-launcher" ];
      };
    };
}
