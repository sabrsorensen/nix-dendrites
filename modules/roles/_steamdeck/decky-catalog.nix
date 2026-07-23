{ ... }:
let
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mkDeckyPlugin = pkgs.callPackage ../../../packages/decky/mk-plugin.nix { };
      animationConfig = pkgs.writeText "nix-animations.json" (
        builtins.toJSON {
          download_animation_ids = [
            "n87jk"
            "n87mG"
            "Yw3jw"
            "Pm4Mp"
            "E1Ne6"
            "YMjez"
            "2YJAE"
            "n7oLn"
            "YGkNY"
            "Yq8Nj"
            "n8dXk"
            "ndeje"
            "PBRmG"
            "nv4lN"
            "YqL2Q"
            "nOAlV"
            "Py0ok"
            "n8j8Y"
            "Pb67V"
            "EXNRN"
            "EXNN7"
            "YopwD"
            "YGqen"
            "Yxe0P"
            "MnZgE"
            "n7qqJ"
            "Pm66k"
            "PBR1v"
            "EA2Lx"
            "YWq9m"
            "nvMq2"
            "ENz0E"
            "n4QDE"
            "n51Ln"
            "PmqqP"
            "YM2Rr"
            "nZ70E"
            "YJ9jE"
            "n3b7W"
            "Erd7g"
            "YGJzg"
            "nZg02"
            "PmlBY"
            "PmXkY"
            "nLQKE"
          ];
          movie_overrides = [
            {
              movie = "boot";
              animation_id = "YqL2Q";
            }
            {
              movie = "suspend";
              animation_id = "PBRmG";
            }
            {
              movie = "throbber";
              animation_id = "PBRmG";
            }
          ];
          randomize = "all";
          force_ipv4 = true;
        }
      );
      cssThemeConfig = pkgs.writeText "nix-css-themes.json" (
        builtins.toJSON {
          theme_downloads = [
            "46095df9-fae2-4af2-8e77-27188af4020d"
            "e4e72a46-51ac-40e0-81da-75303dddb9ec"
            "9ac2bf60-66c5-4f50-aa6b-f897465ba328"
            "723bec9d-4c27-4cd8-a291-2ebaaa54398c"
            "4ba8fe8b-fbd9-457c-94fc-f3555a8877bf"
            "fa803fc3-a391-4cec-9721-7b6c33b13b74"
            "f6df2c7e-3273-4dd7-ae00-2490e7acf301"
            "bb03d57e-c1d7-4aa9-86dc-197d26de1c9f"
          ];
          theme_store_url = "https://api.deckthemes.com";
          themes = {
            "Better Download Page".active = false;
            "Custom Loader" = {
              active = true;
              "Choose Loader" = {
                value = "Loading Buddy";
                components."Custom Image" = "Custom Loader/images/loadingbuddy.gif";
              };
              Fullscreen = "No";
              "Custom Image Scale" = "0";
              "Custom Image Location For Small GIFs" = "Center";
              "Change Background Color" = {
                value = "No";
                components."Background Color" = "#000000";
              };
            };
            "Ethernet Icon" = {
              active = true;
              "Icon Style" = "KDE Plasma";
              "Icon Color" = {
                value = "White";
                components."Icon Color" = "#FFFFFF";
              };
              "Focused Icon Color" = {
                value = "Black";
                components."Icon Color" = "#FFFFFF";
              };
            };
            "Outrun Theme" = {
              active = true;
              "Footer Border" = "Yes";
              "Game Shadow" = "Yes";
              "Button Colors" = "Yes";
              Font = "None";
              "Theme Color 1" = "Cyan";
              "Theme Color 2" = "Green";
            };
            "QAM Hide Tabs" = {
              active = true;
              "Remote Play Together" = "Yes";
              Notifications = "Yes";
              Friends = "Yes";
              Settings = "Yes";
              Performance = "Yes";
              Soundtrack = "No";
              Help = "No";
              Keyboard = "Yes";
            };
            "Remove Broadcasts".active = true;
            "Smaller Quick Access Tabs" = {
              active = true;
              "Tab Height" = "Square";
            };
            "Switch Like Home" = {
              active = true;
              "No Friends" = "No";
              "Lift Hero" = "10";
            };
          };
        }
      );
      brightnessBar = pkgs.callPackage ../../../packages/decky/brightness-bar.nix {
        inherit mkDeckyPlugin;
      };
      catalog = import ../../../packages/decky/catalog.nix { inherit pkgs; };
      patched = {
        "SDH-AnimationChanger" = pkgs.callPackage ../../../packages/decky/animation-changer-enhanced.nix {
          inherit mkDeckyPlugin animationConfig;
        };
        "decky-autosuspend" = pkgs.callPackage ../../../packages/decky/autosuspend.nix {
          inherit mkDeckyPlugin;
        };
        "SDH-CssLoader" = pkgs.callPackage ../../../packages/decky/css-loader.nix {
          inherit mkDeckyPlugin;
          themeConfig = cssThemeConfig;
        };
        "decky-free-loader" = pkgs.callPackage ../../../packages/decky/free-loader.nix {
          inherit mkDeckyPlugin;
        };
        "decky-syncthing" = pkgs.callPackage ../../../packages/decky/syncthing.nix {
          inherit mkDeckyPlugin;
        };
        "decky-XRGaming" = pkgs.callPackage ../../../packages/decky/xrgaming.nix { inherit mkDeckyPlugin; };
      };
    in
    lib.mkIf config.my.host.is.steamdeck {
      jovian.decky-loader.seededSettings = {
        "loader.json" = {
          branch = 0;
          store = 0;
          pluginOrder = [
            "Bluetooth"
            "KDE Connect"
            "XR Gaming"
            "Web Browser"
            "TabMaster"
            "Syncthing"
            "SteamGridDB"
            "ProtonDB Badges"
            "Museck"
            "IsThereAnyDeal for Deck"
            "Free Loader"
            "Decky-Lookup"
            "CSS Loader"
            "Animation Changer"
            "Audio Loader"
            "AutoFlatpaks"
            "AutoSuspend"
            "Brightness Bar"
          ];
        };
        "DeckWebBrowser/settings.json" = {
          defaultTabs = [ "home" ];
          menuPosition = 2;
          searchEngine = 0;
        };
        "decky-free-loader/settings.json" = {
          update_frequency_day = 0;
          update_frequency_hour = 12;
          update_frequency_min = 0;
          notify_on_free_games = true;
          enable_steam_games = true;
          enable_egs_games = false;
          enable_gog_games = false;
          enable_itchio_games = false;
          show_titles = true;
          show_hidden_games = false;
        };
        "decky-isthereanydeal/settings.json" = {
          storefronts = {
            "0" = {
              id = 61;
            };
            Steam = true;
          };
        };
      };
      jovian.decky-loader.plugins =
        catalog
        // patched
        // {
          "decky-brightness-bar" = brightnessBar;
        };
    };
in
module
