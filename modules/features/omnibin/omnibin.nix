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
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      # nixpkgs' cargo-setup-hook now exports LIBSQLITE3_SYS_USE_PKG_CONFIG=1,
      # overriding rusqlite's "bundled" feature, and upstream's buildInputs
      # only lists fuse3. Rebuild the package from the input's own nix files
      # with sqlite added to every buildRustPackage call.
      pkgsWithSqlite = pkgs // {
        rustPlatform = pkgs.rustPlatform // {
          buildRustPackage =
            args:
            pkgs.rustPlatform.buildRustPackage (
              args // { buildInputs = (args.buildInputs or [ ]) ++ [ pkgs.sqlite ]; }
            );
        };
      };
      data = import "${inputs.omnibin}/nix/data.nix" { inherit pkgs system; };
      omnibin = import "${inputs.omnibin}/nix/omnibin.nix" {
        pkgs = pkgsWithSqlite;
        inherit (data) database;
      };
      omnibin-shell = import "${inputs.omnibin}/nix/omnibin-shell.nix" { inherit pkgs omnibin; };
    in
    {
      options.my.host.features.omnibin =
        lib.mkEnableOption "omnibin-shell, a per-shell lazy view of every binary nixpkgs ever shipped";

      # Only omnibin-shell: the lazy /nix/store lives in a mount namespace that
      # dies with the shell. Upstream's NixOS module (services.omnibin) mounts
      # it machine-wide and is meant for VMs/containers, not workstations.
      config = lib.mkIf config.my.host.features.omnibin {
        warnings = [
          ''
            omnibin: rebuilt from the input's nix/*.nix with sqlite in
            buildInputs, because nixpkgs' cargo-setup-hook now forces
            LIBSQLITE3_SYS_USE_PKG_CONFIG=1 and upstream only lists fuse3.
            Switch back to inputs.omnibin.packages.<system>.omnibin-shell in
            modules/features/omnibin/omnibin.nix once this prints a match:
              grep -n sqlite "$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.omnibin.outPath')/nix/omnibin.nix"
          ''
        ];

        environment.systemPackages = [ omnibin-shell ];
      };
    };
}
