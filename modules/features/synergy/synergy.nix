{ ... }:
let
  supportedSystem = "x86_64-linux";
in
{
  flake.modules.nixos.synergy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.host;
      fetchSymless = pkgs.callPackage ./_fetch-symless.nix { };
      packageArgs = { inherit lib pkgs fetchSymless; };
      supported = pkgs.stdenv.hostPlatform.system == supportedSystem;
    in
    {
      options.my.host = {
        features = {
          synergy = lib.mkEnableOption "Synergy 1 (nixpkgs' open-source 1.14 build; X11 only)";
          synergy3 = lib.mkEnableOption "Synergy 3 (Symless's licensed build)";
          synergy4 = lib.mkEnableOption "Synergy 4 Dragon Beta (Symless's licensed build)";
        };
        synergy.role = lib.mkOption {
          type = lib.types.enum [
            "server"
            "client"
          ];
          default = "client";
          description = ''
            Whether this host shares its keyboard and mouse (server) or is
            controlled by another host (client). Synergy 3/4 pick the role in
            the app; this only decides which ports the firewall opens.
          '';
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.features.synergy (import ./_synergy1.nix { inherit lib pkgs; }))

        (lib.mkIf (cfg.features.synergy3 || cfg.features.synergy4) {
          assertions = [
            {
              assertion = supported;
              message = "my.host.features.synergy3/synergy4 are only supported on ${supportedSystem}; Symless ships x86_64-only Linux builds.";
            }
            {
              # Both run their own core on port 24800 from the session.
              assertion = !(cfg.features.synergy3 && cfg.features.synergy4);
              message = "my.host.features.synergy3 and synergy4 can't both be enabled on ${cfg.name}: each starts its own core on port 24800.";
            }
          ];
          my.unfreePackageNames = [
            "synergy3"
            "synergy3-unwrapped"
            "synergy4"
            "synergy4-unwrapped"
          ];
        })

        (lib.mkIf (cfg.features.synergy3 && supported) (
          import ./_synergy3.nix {
            inherit lib;
            inherit (cfg.synergy) role;
            package = import ./_synergy3-package.nix packageArgs;
          }
        ))

        (lib.mkIf (cfg.features.synergy4 && supported) (
          import ./_synergy4.nix {
            inherit lib;
            inherit (cfg.synergy) role;
            package = import ./_synergy4-package.nix packageArgs;
          }
        ))
      ];
    };
}
