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

  # Built from source; the version is read from the pinned CMakeLists.txt, so
  # a flake.lock bump is the whole update. Review CHANGELOG.md when it moves.
  flake-file.inputs.reolink-native-linux = {
    url = "github:TodesengelX/reolink-native-linux";
    flake = false;
  };

  flake.modules.nixos.reolink =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.reolink =
        lib.mkEnableOption "Reolink camera tooling (reolink-cli and the native Linux client)";

      config = lib.mkIf config.my.host.features.reolink {
        environment.systemPackages = [
          (pkgs.callPackage ./_reolink-cli.nix { reolink-cli-src = inputs.reolink-cli; })
          (pkgs.callPackage ./_reolink-native-linux.nix {
            reolink-native-linux-src = inputs.reolink-native-linux;
          })
        ];
        my.unfreePackageNames = [ "reolink-cli" ];
      };
    };
}
