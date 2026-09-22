{ lib, pkgs }:
{
  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
      message = "my.host.features.noMansSky is only supported on x86_64-linux because NMSE ships a prebuilt x86_64 AppImage.";
    }
  ];

  environment.systemPackages = lib.optional (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
    pkgs.callPackage ./_nmse.nix { }
  );
}
