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

  warnings = [
    ''
      nmse runs through its own appimage-run overridden with libunwind (its
      bundled Wine's ntdll.so needs libunwind.so.8). Remove the override in
      modules/features/nomanssky/_nmse.nix once nixpkgs ships libunwind in
      appimage-run itself -- check with:
        grep -n libunwind "$(nix eval --raw .#nixosConfigurations.kamino.pkgs.path)"/pkgs/build-support/appimage/default.nix
    ''
  ];
}
