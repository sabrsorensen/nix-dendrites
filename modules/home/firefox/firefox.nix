{ inputs, ... }:
{
  flake-file.inputs = {
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem = import ./firefox-addons/_updater.nix { inherit inputs; };

  # This is deliberately a normal broadcast module. The Firefox feature gates
  # both the NUR overlay and the Home Manager profile on hosts that use it.
  flake.modules.nixos.firefox =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      enabled = host.features.firefox && host.home.enable;
      username = host.home.username;
      profileName = username;
      buildMozillaXpiAddon =
        {
          pname,
          version,
          addonId,
          url,
          sha256,
          meta,
          ...
        }:
        pkgs.stdenv.mkDerivation {
          name = "${pname}-${version}";
          inherit meta;
          src = pkgs.fetchurl { inherit url sha256; };
          preferLocalBuild = true;
          allowSubstitutes = true;
          passthru = { inherit addonId; };
          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            install -m644 "$src" "$dst/${addonId}.xpi"
          '';
        };
      customAddons = pkgs.callPackage ./firefox-addons/_content.nix {
        inherit buildMozillaXpiAddon;
      };
      rycee = pkgs.nur.repos.rycee.firefox-addons;
      addons =
        with rycee;
        [
          bitwarden
          dark-mode-webextension
          decentraleyes
          multi-account-containers
          old-reddit-redirect
          plasma-integration
          privacy-badger
          privacy-possum
          reddit-enhancement-suite
          refined-github
          return-youtube-dislikes
          sidebery
          ublock-origin
        ]
        ++ (with customAddons; [
          fast-tab-switcher
          herp-derp-for-youtube
          pixel-punk-dynamic-theme
          recipe-filter
          sticky-window-containers
          whatcampaign
        ]);
      cssRoot = "${config.home-manager.users.${username}.xdg.configHome}/mozilla/firefox/${profileName}";
      nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      profileContent = import ./_content.nix { inherit inputs; };
    in
    lib.mkIf enabled (
      profileContent (
        args
        // {
          inherit
            addons
            cssRoot
            host
            nixIcon
            profileName
            username
            ;
        }
      )
    );
}
