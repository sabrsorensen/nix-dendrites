{ inputs, ... }:
{
  # Upstream commits package.json (version) and checksums/v<version>.sha256
  # alongside each release, so `nix flake update` moving this input is the
  # signal to review CHANGELOG.md. To hold back a release, pin the input to a
  # tag (e.g. "github:reolink/reolink-cli/v0.18.3") and note it in
  # docs/upstream-tracking.md.
  flake-file.inputs.reolink-cli = {
    url = "github:reolink/reolink-cli";
    flake = false;
  };

  flake.modules.nixos.reolink-cli =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.reolinkCli =
        lib.mkEnableOption "the proprietary LAN-only Reolink camera CLI";

      config = lib.mkIf config.my.host.features.reolinkCli {
        environment.systemPackages = [
          (pkgs.callPackage ./_package.nix { reolink-cli-src = inputs.reolink-cli; })
        ];
        my.unfreePackageNames = [ "reolink-cli" ];
      };
    };
}
