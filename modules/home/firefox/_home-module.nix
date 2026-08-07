{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  profileName = config.home.username;
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
  customAddons = pkgs.callPackage ./firefox-addons/_firefox-addons.nix {
    inherit buildMozillaXpiAddon;
  };
  nurPkgs = pkgs.extend inputs.nur.overlays.default;
  addons =
    with nurPkgs.nur.repos.rycee.firefox-addons;
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
in
(import ./_firefox.nix { inherit inputs; }) {
  inherit addons lib profileName;
  cssRoot = "${config.xdg.configHome}/mozilla/firefox/${profileName}";
  nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
}
