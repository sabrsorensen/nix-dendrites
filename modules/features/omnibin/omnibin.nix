{ inputs, ... }:
{
  flake-file.inputs.omnibin = {
    url = "github:fzakaria/omnibin";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.omnibin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.omnibin =
        lib.mkEnableOption "omnibin-shell, a per-shell lazy view of every binary nixpkgs ever shipped";

      # Only omnibin-shell: the lazy /nix/store lives in a mount namespace that
      # dies with the shell. Upstream's NixOS module (services.omnibin) mounts
      # it machine-wide and is meant for VMs/containers, not workstations.
      config = lib.mkIf config.my.host.features.omnibin {
        environment.systemPackages = [
          inputs.omnibin.packages.${pkgs.stdenv.hostPlatform.system}.omnibin-shell
        ];
      };
    };
}
