{ inputs, ... }:
{
  # Source-only: the package is a single callPackage file, so build it with our
  # nixpkgs instead of the upstream flake's own nixos-26.05 + flake-utils.
  flake-file.inputs.danieltallon-nix-packages = {
    url = "github:DanielTallon/nix-packages";
    flake = false;
  };

  flake.modules.nixos.boot-gardener =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.bootGardener =
        lib.mkEnableOption "boot-gardener, for pruning boot generations and rescuing a full /boot";

      # Only prune/harvest/gc and `boot-gardener rescue` apply here: pinning is
      # Limine-only and needs an out-of-tree module plus --impure rebuilds.
      config = lib.mkIf config.my.host.features.bootGardener {
        environment.systemPackages = [
          (pkgs.callPackage "${inputs.danieltallon-nix-packages}/boot-gardener/boot-gardener.nix" { })
        ];
      };
    };
}
