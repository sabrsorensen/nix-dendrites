{
  flake.modules.homeManager.firefox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Load metadata for dynamic extensions from the pre-fetched file
      addonMetadata = builtins.fromJSON (builtins.readFile ./firefox_addons.json);

      # Function to build a Firefox XPI add-on
      buildFirefoxXpiAddon =
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
        let
          # Substitute pname if it matches "cloud-2-butt-plus"
          adjustedPname = if pname == "cloud-2-butt-plus" then "cloud-to-butt-plus" else pname;
        in
        stdenv.mkDerivation {
          name = "${adjustedPname}-${version}";

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

      # Generate derivations for dynamic extensions
      dynamicAddons = map (
        addon:
        buildFirefoxXpiAddon {
          pname = addon.pname;
          version = addon.version; # Pass the version field
          addonId = addon.addonId;
          url = addon.url;
          sha256 = addon.sha256;
          meta = {
            homepage = addon.homepage;
            description = addon.description;
            license = addon.license;
          };
        }
      ) addonMetadata;

      currHash = "sha256-4gU/AaMC37BSZAyIG5/7e5KPp52uz6xGM7z2zJMtd+U=";
      cssRepo = pkgs.fetchFromGitHub {
        owner = "MrOtherGuy";
        repo = "firefox-csshacks";
        rev = "master";
        hash = currHash;
      };
      readCss = path: builtins.readFile (cssRepo + "/${path}");

      username = "sam";
      userChromePath = ".mozilla/firefox/${username}/chrome";

      cssFiles = [
        "chrome/hide_tabs_toolbar_v2.css"
        "content/css_scrollbar_width_color.css"
        "content/newtab_background_color.css"
        "content/transparent_reader_toolbar.css"
      ];

      homeFileAttrs = lib.listToAttrs (
        map (path: {
          name = "${userChromePath}/${path}";
          value.text = readCss path;
        }) cssFiles
      );
    in
    {
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
          extensions.packages = dynamicAddons;
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
