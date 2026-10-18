{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      options.my.host.features.determinateNix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Determinate Nix instead of the upstream Nix daemon.";
      };

      # Keep the daemon switch visible in host facts for the rare host that
      # needs to opt out of Determinate Nix.
      config = lib.mkMerge [
        { determinate.enable = config.my.host.features.determinateNix; }

        # Determinate Nix >= 3.23 emits extra internal-json activity/result
        # types (10111, 10113) for its OTel tracing that nom 2.2.0 can't
        # parse, breaking `nom` and `nh` (maralorn/nix-output-monitor#320).
        # Apply the unmerged fix PR #321. The patch URL tracks the PR head, so
        # a new push to it fails the hash check instead of landing silently.
        # nh picks this up through the overlay; no separate override needed.
        (lib.mkIf config.my.host.features.determinateNix {
          nixpkgs.overlays = [
            (_: prev: {
              nix-output-monitor = prev.nix-output-monitor.override {
                extraComposeFunctions = [
                  (prev.haskell.lib.compose.appendPatch (
                    prev.fetchpatch2 {
                      url = "https://patch-diff.githubusercontent.com/raw/maralorn/nix-output-monitor/pull/321.patch";
                      relative = "nix-output-monitor";
                      hash = "sha256-d20jaA7iTSZ+3s7fV2Ql//tfnpqu6lJQmpOX1kfy4V8=";
                    }
                  ))
                ];
              };
            })
          ];
          warnings = [
            ''
              pkgs.nix-output-monitor carries maralorn/nix-output-monitor#321
              (unknown internal-json activity/result types from Determinate
              Nix, issue #320). Remove the overlay in
              modules/system/nix/determinate/_determinate.nix once #321 (or an
              equivalent fix) is merged and released in nixpkgs -- check with:
                gh pr view 321 -R maralorn/nix-output-monitor --json state
                nix eval --raw nixpkgs#nix-output-monitor.version
            ''
          ];
        })
      ];
    };
}
