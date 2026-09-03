{ inputs }:
{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  profileName = config.home.username;
  cssRoot = "${config.xdg.configHome}/mozilla/firefox/${profileName}";
  nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
{
  home = {
    file = {
      "${cssRoot}/chrome/chrome/hide_tabs_toolbar_v2.css".source =
        inputs.firefox-csshacks + "/chrome/hide_tabs_toolbar_v2.css";
      "${cssRoot}/chrome/content/css_scrollbar_width_color.css".source =
        inputs.firefox-csshacks + "/content/css_scrollbar_width_color.css";
      "${cssRoot}/chrome/content/newtab_background_color.css".source =
        inputs.firefox-csshacks + "/content/newtab_background_color.css";
      "${cssRoot}/chrome/content/transparent_reader_toolbar.css".source =
        inputs.firefox-csshacks + "/content/transparent_reader_toolbar.css";
    };
  }
  // lib.optionalAttrs (options.home ? persistence) {
    # enable (not just directories) must be gated: allPersistentStoragePaths in
    # the impermanence module collects every home.persistence.<path> submodule
    # with enable = true regardless of whether its directories/files end up
    # empty, so an ungated `directories = mkIf ... [...]` still registers this
    # host as having a persistent path and trips its "not persisted" warnings.
    persistence."/persistent" = {
      enable = config.my.features.persistence or false;
      directories = [ ".config/mozilla/firefox" ];
    };
  };
  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings."*".installation_mode = "allowed";
      DefaultDownloadDirectory = "\${home}/Downloads";
    };
    profiles.${profileName} = {
      isDefault = true;
      name = profileName;
      extraConfig = ''
        user_pref("extensions.autoDisableScopes", 0);
        user_pref("extensions.enabledScopes", 15);
      '';
      userChrome = "@import url(chrome/hide_tabs_toolbar_v2.css);";
      userContent = ''
        @import url(content/css_scrollbar_width_color.css);
        @import url(content/newtab_background_color.css);
        @import url(content/transparent_reader_toolbar.css);
      '';
      extensions.packages = addons;
      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
        engines = {
          bing.metaData.hidden = true;
          ebay.metaData.hidden = true;
          github = {
            name = "GitHub";
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = [ "@gh" ];
          };
          MyNixOS = {
            urls = [
              {
                template = "https://mynixos.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixIcon;
            definedAliases = [ "@mn" ];
          };
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixIcon;
            definedAliases = [ "@np" ];
          };
          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixIcon;
            definedAliases = [ "@no" ];
          };
          "Nix Wiki" = {
            name = "NixOS Wiki";
            urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
            iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
            definedAliases = [ "@nw" ];
          };
          "Home Manager" = {
            urls = [
              {
                template = "https://mipmip.github.io/home-manager-option-search/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixIcon;
            definedAliases = [ "@hm" ];
          };
        };
      };
      settings = {
        "browser.startup.homepage" = "about:home";
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "extensions.activeThemeID" = "{a5b9a884-8ef0-4368-bc65-bf5e122d8929}";
        "extensions.pocket.enabled" = false;
        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.feeds.showFirstRunUI" = false;
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "browser.rights.3.shown" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.startup.page" = 3;
        "browser.uitour.enabled" = false;
        "startup.homepage_override_url" = "";
        "trailhead.firstrun.didSeeAboutWelcome" = true;
        "browser.bookmarks.restore_default_bookmarks" = false;
        "browser.bookmarks.addedImportButton" = true;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
        "browser.newtabpage.blocked" = lib.genAttrs [
          "26UbzFJ7qT9/4DhodHKA1Q=="
          "4gPpjkxgZzXPVtuEoAL9Ig=="
          "eV8/WsSLxHadrTL1gAxhug=="
          "gLv0ja2RYVgxKdp0I5qwvA=="
          "K00ILysCaEq8+bEqV/3nuw=="
          "T9nJot5PurhJSy8n038xGA=="
        ] (_: 1);
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "app.shield.optoutstudies.enabled" = false;
        "browser.discovery.enabled" = false;
        "browser.ping-centre.telemetry" = false;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.sessions.current.clean" = true;
        "devtools.onboarding.telemetry.logged" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.hybridContent.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.prompted" = 2;
        "toolkit.telemetry.rejected" = true;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.unifiedIsOptIn" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "identity.fxaccounts.enabled" = true;
        "signon.rememberSignons" = false;
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.ai.control.default" = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.pdfjsAltText" = "blocked";
        "browser.ai.control.sidebarChatbot" = "blocked";
        "browser.ai.control.smartTabGroups" = "blocked";
      };
    };
  };
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "text/xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };
}
