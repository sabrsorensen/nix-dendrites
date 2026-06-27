{ buildMozillaXpiAddon, fetchurl, lib, stdenv }:
  {
    "fast-tab-switcher" = buildMozillaXpiAddon {
      pname = "fast-tab-switcher";
      version = "2.7.0";
      addonId = "tabswitcher@volinsky.net";
      url = "https://addons.mozilla.org/firefox/downloads/file/3555113/fast_tab_switcher-2.7.0.xpi";
      sha256 = "7d7265235183447fe7bada0ff01eab0d36ef814c6e500a9fa1e0e9dd9cb2fc91";
      meta = with lib;
      {
        homepage = "https://github.com/tapapax/firefox-fts";
        description = "Fast Tab Switcher allows you to find and switch to any tab immediately. It is very useful if you have multiple windows and/or lots of tabs opened. Just press Ctrl+Space!";
        license = licenses.gpl3;
        mozPermissions = [ "tabs" "sessions" ];
        platforms = platforms.all;
      };
    };
    "herp-derp-for-youtube" = buildMozillaXpiAddon {
      pname = "herp-derp-for-youtube";
      version = "1.6.10";
      addonId = "jid1-q98n8ueq0rrwVA@jetpack";
      url = "https://addons.mozilla.org/firefox/downloads/file/3382726/herp_derp_for_youtube-1.6.10.xpi";
      sha256 = "d3129673afe818a7d7a37dee6b31060a9d6507b3bbd969c98941dac4fa55cf55";
      meta = with lib;
      {
        homepage = "https://www.tannr.com/herp-derp-youtube-comments/";
        description = "Significantly improves YouTube comments by replacing them with random herps and derps. When visiting a YouTube video, comments will be \"herp derped\". Clicking on a comment reverts it back to the original version.";
        license = licenses.mit;
        mozPermissions = [ "https://www.youtube.com/*" ];
        platforms = platforms.all;
      };
    };
    "pixel-punk-dynamic-theme" = buildMozillaXpiAddon {
      pname = "pixel-punk-dynamic-theme";
      version = "1.3.2";
      addonId = "{a5b9a884-8ef0-4368-bc65-bf5e122d8929}";
      url = "https://addons.mozilla.org/firefox/downloads/file/3947004/pixel_punk_dynamic_theme-1.3.2.xpi";
      sha256 = "7be58005e4e53aa62d9c21d072464f63788708730af3dd165add58de07526e57";
      meta = with lib;
      {
        description = "An animated Cyberpunk inspired pixel Theme for Firefox 89 and up.";
        license = licenses.cc-by-nc-sa-30;
        mozPermissions = [];
        platforms = platforms.all;
      };
    };
    "recipe-filter" = buildMozillaXpiAddon {
      pname = "recipe-filter";
      version = "0.4resigned1";
      addonId = "{8b2164f4-fdb6-47eb-b692-312cc6d04f6b}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4275461/recipe_filter-0.4resigned1.xpi";
      sha256 = "5a19cae6a847319a7cb5a95fffd5750302216f652d3eedc943f61bb9b5af93b2";
      meta = with lib;
      {
        description = "This extension will detect recipes on any page you visit and will highlight them at the top of the page. \n\nNo more hunting for the actual recipe when you visit a long-winded food blog!\n\nFork of the excellent chrome extension.";
        license = licenses.gpl3;
        mozPermissions = [
          "storage"
          "contextMenus"
          "http://*/*"
          "https://*/*"
        ];
        platforms = platforms.all;
      };
    };
    "sticky-window-containers" = buildMozillaXpiAddon {
      pname = "sticky-window-containers";
      version = "1.0.4";
      addonId = "{a263f1ee-2fa8-4caf-be73-7421b54efa39}";
      url = "https://addons.mozilla.org/firefox/downloads/file/3768188/sticky_window_containers-1.0.4.xpi";
      sha256 = "8809492e18d7b5fe1e3ea8c12bd660311bf93de2390b7dba959fe4fffa35d72d";
      meta = with lib;
      {
        homepage = "https://github.com/chronakis/firefox-sticky-window-containers";
        description = "Tabs open in the same container as the first tab in the window.";
        license = licenses.mpl20;
        mozPermissions = [
          "<all_urls>"
          "contextualIdentities"
          "cookies"
          "tabs"
          "webNavigation"
        ];
        platforms = platforms.all;
      };
    };
    "whatcampaign" = buildMozillaXpiAddon {
      pname = "whatcampaign";
      version = "1.0.9";
      addonId = "{c392f810-68ef-49da-9ea0-d76d6e967f74}";
      url = "https://addons.mozilla.org/firefox/downloads/file/3617919/whatcampaign-1.0.9.xpi";
      sha256 = "9cd4ab8681cb6ceb2d281b08df7c426e4b2307a69c7fbd8021b2a961ce8be3fe";
      meta = with lib;
      {
        homepage = "https://c0debabe.com";
        description = "This privacy add-on protects your identity by changing tracking parameters, published as part of Projekt ONI.";
        license = licenses.mpl20;
        mozPermissions = [ "webRequest" "tabs" "*://*/*" "*://*/*utm*" ];
        platforms = platforms.all;
      };
    };
  }