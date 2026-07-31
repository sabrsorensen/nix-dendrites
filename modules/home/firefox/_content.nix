{ inputs }:
{
  addons,
  cssRoot,
  host,
  lib,
  nixIcon,
  profileName,
  username,
  ...
}:
{
  nixpkgs.overlays = [ inputs.nur.overlays.default ];
  home-manager.users.${username} = {
    home.persistence = lib.mkIf host.features.persistenceFirefox {
      "/persistent".directories = [ ".config/mozilla/firefox" ];
    };
    home.file = {
      "${cssRoot}/chrome/chrome/hide_tabs_toolbar_v2.css".source =
        inputs.firefox-csshacks + "/chrome/hide_tabs_toolbar_v2.css";
      "${cssRoot}/chrome/content/css_scrollbar_width_color.css".source =
        inputs.firefox-csshacks + "/content/css_scrollbar_width_color.css";
      "${cssRoot}/chrome/content/newtab_background_color.css".source =
        inputs.firefox-csshacks + "/content/newtab_background_color.css";
      "${cssRoot}/chrome/content/transparent_reader_toolbar.css".source =
        inputs.firefox-csshacks + "/content/transparent_reader_toolbar.css";
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
  };
}
