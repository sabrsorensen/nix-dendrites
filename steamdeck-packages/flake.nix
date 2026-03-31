{
  description = "Decky Loader Plugins for Steam Deck";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      mkDeckyPackages =
        pkgs:
        let
          mkDeckyPlugin = pkgs.callPackage ./mkDeckyPlugin.nix { };
          callPackage =
            file: args:
            let
              packageFn = import file;
              extraArgs =
                nixpkgs.lib.optionalAttrs (builtins.hasAttr "mkDeckyPlugin" (builtins.functionArgs packageFn))
                  {
                    inherit mkDeckyPlugin;
                  };
            in
            pkgs.callPackage file (extraArgs // args);
        in
        rec {
          decky-animation-changer = callPackage ./decky-animation-changer.nix { };
          decky-animation-changer-enhanced =
            callPackage ./SDH-AnimationChanger/decky-animation-changer-enhanced.nix
              {
                inherit callPackage;
              };
          decky-css-loader = callPackage ./decky-css-loader.nix {
            inherit callPackage;
          };
          decky-audio-loader = callPackage ./decky-audio-loader.nix { };
          decky-xrgaming = callPackage ./decky-xrgaming.nix { };
          decky-steamgriddb = callPackage ./decky-steamgriddb.nix { };
          decky-free-loader = callPackage ./decky-free-loader.nix { };
          decky-lookup = callPackage ./decky-lookup.nix { };
          decky-isthereanydeal = callPackage ./decky-isthereanydeal.nix { };
          decky-protondb = callPackage ./decky-protondb.nix { };
          decky-tabmaster = callPackage ./decky-tabmaster.nix { };
          decky-brightness-bar = callPackage ./decky-brightness-bar.nix { };
          decky-autoflatpaks = callPackage ./decky-autoflatpaks.nix { };
          decky-autosuspend = callPackage ./decky-autosuspend.nix { };
          decky-syncthing = callPackage ./decky-syncthing-jovian/decky-syncthing-jovian.nix { };
          decky-bluetooth = callPackage ./decky-bluetooth.nix { };
          decky-kdeconnect = callPackage ./decky-kdeconnect.nix { };
          decky-web-browser = callPackage ./decky-web-browser.nix { };
          decky-museck = callPackage ./decky-museck.nix { };
          default = pkgs.symlinkJoin {
            name = "steamdeck-packages";
            paths = [
              decky-animation-changer
              decky-animation-changer-enhanced
              decky-css-loader
              decky-audio-loader
              decky-xrgaming
              decky-steamgriddb
              decky-free-loader
              decky-lookup
              decky-isthereanydeal
              decky-protondb
              decky-tabmaster
              decky-brightness-bar
              decky-autoflatpaks
              decky-autosuspend
              decky-syncthing
              decky-bluetooth
              decky-kdeconnect
              decky-web-browser
              decky-museck
            ];
          };
        };
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        mkDeckyPackages pkgs
      );

      # Make packages available in overlays
      overlays.default = final: prev: mkDeckyPackages final;
    };
}
