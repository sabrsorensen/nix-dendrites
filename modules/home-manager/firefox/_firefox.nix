{
  inputs,
  ...
}:
{
  flake.modules.homeManager.firefox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ryceeAddonAttrByPname = {
        adnauseam = "adnauseam";
        "bitwarden-password-manager" = "bitwarden";
        "dark-mode-webextension" = "dark-mode-webextension";
        decentraleyes = "decentraleyes";
        "multi-account-containers" = "multi-account-containers";
        "old-reddit-redirect" = "old-reddit-redirect";
        "plasma-integration" = "plasma-integration";
        "privacy-badger17" = "privacy-badger";
        "privacy-possum" = "privacy-possum";
        "reddit-enhancement-suite" = "reddit-enhancement-suite";
        "refined-github-" = "refined-github";
        "return-youtube-dislikes" = "return-youtube-dislikes";
        sidebery = "sidebery";
      };

      customAddonPnames = [
        "fast-tab-switcher"
        "herp-derp-for-youtube"
        "pixel-punk-dynamic-theme"
        "recipe-filter"
        "sticky-window-containers"
        "whatcampaign"
      ];

      buildMozillaXpiAddon =
        {
          stdenv ? pkgs.stdenv,
          fetchurl ? pkgs.fetchurl,
          pname,
          version,
          addonId,
          url,
          sha256,
          meta,
          ...
        }:
        stdenv.mkDerivation {
          name = "${pname}-${version}";

          inherit meta;

          src = fetchurl { inherit url sha256; };

          preferLocalBuild = true;
          allowSubstitutes = true;

          passthru = { inherit addonId; };

          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            install -v -m644 "$src" "$dst/${addonId}.xpi"
          '';
        };

      ryceeAddons =
        let
          firefoxAddons = pkgs.nur.repos.rycee.firefox-addons;
        in
        map (pname: builtins.getAttr ryceeAddonAttrByPname.${pname} firefoxAddons) (
          builtins.attrNames ryceeAddonAttrByPname
        );

      customAddonSet = pkgs.callPackage ./_custom_firefox_addons.nix {
        inherit buildMozillaXpiAddon;
      };
      customAddons = map (pname: builtins.getAttr pname customAddonSet) customAddonPnames;

      cssRepo = inputs.firefox-csshacks;
      username = config.home.username;
      userChromePath = "${config.xdg.configHome}/mozilla/firefox/${username}/chrome";

      cssFiles = [
        "chrome/hide_tabs_toolbar_v2.css"
        "content/css_scrollbar_width_color.css"
        "content/newtab_background_color.css"
        "content/transparent_reader_toolbar.css"
      ];

      homeFileAttrs = lib.listToAttrs (
        map (path: {
          name = "${userChromePath}/${path}";
          value.source = cssRepo + "/${path}";
        }) cssFiles
      );
    in
    lib.mkIf config.my.host.features.gui {
      home.file = homeFileAttrs;

      programs.firefox = {
        enable = true;
        policies = {
          ExtensionSettings = {
            "*" = {
              installation_mode = "allowed";
            };
          };
          DefaultDownloadDirectory = "\${home}/Downloads";
        };
        profiles.${username} = {
          extraConfig = ''
            user_pref("extensions.autoDisableScopes", 0);
            user_pref("extensions.enabledScopes", 15);
          '';
          userChrome = ''
            @import url(chrome/hide_tabs_toolbar_v2.css);
          '';
          userContent = ''
            @import url(content/css_scrollbar_width_color.css);
            @import url(content/newtab_background_color.css);
            @import url(content/transparent_reader_toolbar.css);
          '';
          search = {
            force = true;
            default = "ddg";
            privateDefault = "ddg";
            #order = [ "ddg" "google" "gh" "np" "no" "nw" "hm" "amazondotcom-us" "ebay" ];
            engines = {
              "bing".metaData.hidden = true;
              "ebay".metaData.hidden = true;
              "github" = {
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
              "MyNixOS" = {
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
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@hm" ];
              };
            };
          };
          bookmarks = { };
          containers = {
            #shopping = {
            #  color = "blue";
            #  icon = "cart";
            #  id = 1;
            #};
          };
          extensions.packages = ryceeAddons ++ customAddons;
          isDefault = true;
          name = username;
          settings = {
            "browser.startup.homepage" = "about:home";
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "extensions.activeThemeID" = "{a5b9a884-8ef0-4368-bc65-bf5e122d8929}";
            "extensions.pocket.enabled" = false;

            # Disable irritating first-run stuff
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

            # Don't ask for download dir
            #"browser.download.useDownloadDir" = false;

            # Disable crappy home activity stream page
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
            "browser.newtabpage.blocked" = lib.genAttrs [
              # Youtube
              "26UbzFJ7qT9/4DhodHKA1Q=="
              # Facebook
              "4gPpjkxgZzXPVtuEoAL9Ig=="
              # Wikipedia
              "eV8/WsSLxHadrTL1gAxhug=="
              # Reddit
              "gLv0ja2RYVgxKdp0I5qwvA=="
              # Amazon
              "K00ILysCaEq8+bEqV/3nuw=="
              # Twitter
              "T9nJot5PurhJSy8n038xGA=="
            ] (_: 1);

            # Disable some telemetry
            "app.shield.optoutstudies.enabled" = false;
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
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
            # Disable "save password" prompt
            "signon.rememberSignons" = false;
            # Harden
            "privacy.trackingprotection.enabled" = true;
            "dom.security.https_only_mode" = true;
            # Layout
            #"browser.uiCustomization.state" = builtins.toJSON {
            #  currentVersion = 20;
            #  newElementCount = 5;
            #  dirtyAreaCache = ["nav-bar" "PersonalToolbar" "toolbar-menubar" "TabsToolbar" "widget-overflow-fixed-list"];
            #  placements = {
            #    PersonalToolbar = ["personal-bookmarks"];
            #    TabsToolbar = ["tabbrowser-tabs" "new-tab-button" "alltabs-button"];
            #    nav-bar = ["back-button" "forward-button" "stop-reload-button" "urlbar-container" "downloads-button" "ublock0_raymondhill_net-browser-action" "_testpilot-containers-browser-action" "reset-pbm-toolbar-button" "unified-extensions-button"];
            #    toolbar-menubar = ["menubar-items"];
            #    unified-extensions-area = [];
            #    widget-overflow-fixed-list = [];
            #  };
            #  seen = ["save-to-pocket-button" "developer-button" "ublock0_raymondhill_net-browser-action" "_testpilot-containers-browser-action"];
            #};
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
    };
}
