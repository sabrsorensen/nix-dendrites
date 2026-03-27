{ pkgs, ... }:
{
  jovian.decky-loader.seededSettings = {
    "loader.json" = {
      branch = 0;
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
      store = 0;
    };

    "DeckWebBrowser/settings.json" = {
      defaultTabs = [ "home" ];
      menuPosition = 2;
      searchEngine = 0;
    };

    "decky-web-browser/settings.json" = {
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

  jovian.decky-loader.plugins = {
    "decky-XRGaming" = pkgs.decky-xrgaming;
    "SDH-AnimationChanger" = pkgs.decky-animation-changer-enhanced.withAnimations {
      downloadAnimationIds = [
        "Yw3jw" # bluey
        "n8dXk" # lego
        "Pm4Mp" # Spongebob
        "E1Ne6" # new desktop futurama
        "Yq8Nj" # Metroid Prime Boot screen (Version 2)
        "n87jk" # Big Enough scream meme (OLED version)
        "YM2Rr" # RETRO WAVE 2
        "YqL2Q" # Zelda TOTK Purah Pad startup (OLED)
        "Erd7g" # Default Steam Deck Boot – (Neon Cyan) Variant
        "EA2Lx" # Analytics - Steam Deck Startup Movie wR_sixtee6 Gaming
        "EXNRN" # FATHER!
        "nOAlV" # Kirby Stampede 2 (But Pink Logo)
        "EXNN7" # Game Changer
        "YMjez" # Bob's Burgers [BOOT]
        "Py0ok" # More Kirby Stampede!
        "nZ70E" # Outrun Deck
        "ndeje" # Steam Hades
        "PBRmG" # Sheikah Slate Suspend
        "YopwD" # Elevator
        "YGqen" # Nintendo Gameboy
        "n7qqJ" # crash1
        "Pm66k" # Cowboy Bebop
        "PBR1v" # cowboy bebop
        "YGJzg" # suspend portal cores
        "Pb67V" # Click Clock Wood
        "YWq9m" # Falling into Zelda
        "nvMq2" # steam Deck xv Splash
        "nZg02" # N64 Boot
        "PmlBY" # Flowing Particles
        "MnZgE" # Star Wars Intro (Disney+)
        "nv4lN" # Decky Loader Crash
        "ENz0E" # PS1 startup movie
        "2YJAE" # Easter Egg - Mini Motorways
        "PmXkY" # Randomly Selected
        "n7oLn" # Kakariko Village from OOT
        "n87mG" # Kingsman Bootup
        "n4QDE" # Corneria
        "n51Ln" # Xbox startup
        "PmqqP" # The Simpsons
        "Yxe0P" # Futurama
        "n8j8Y" # Borderlands Psycho startup
        "YJ9jE" # Original XBOX startup
        "n8KxP" # Family Guy
        "YGkNY" # NGE standby animation
        "nLQKE" # Monster Inc - Intro
        "n3b7W" # Appa Yip Yip
      ];
      movieOverrides = [
        {
          movie = "boot";
          animationId = "YqL2Q";
        }
        {
          movie = "suspend";
          animationId = "PBRmG";
        }
        {
          movie = "throbber";
          animationId = "PBRmG";
        }
      ];
      randomize = "all";
    };
    "SDH-CssLoader" = pkgs.decky-css-loader.withThemes {
      themeDownloads = [
        "46095df9-fae2-4af2-8e77-27188af4020d" # Custom Loader
        "e4e72a46-51ac-40e0-81da-75303dddb9ec" # Remove Broadcasts
        "9ac2bf60-66c5-4f50-aa6b-f897465ba328" # Switch Like Home
        "723bec9d-4c27-4cd8-a291-2ebaaa54398c" # Better Download Page
        "4ba8fe8b-fbd9-457c-94fc-f3555a8877bf" # Outrun Theme
        "fa803fc3-a391-4cec-9721-7b6c33b13b74" # QAM Hide Tabs
        "f6df2c7e-3273-4dd7-ae00-2490e7acf301" # Smaller Quick Access Tabs
        "bb03d57e-c1d7-4aa9-86dc-197d26de1c9f" # Ethernet Icon
      ];
      themeStoreUrl = "https://api.deckthemes.com";
      themes = {
        "Better Download Page" = {
          active = false;
        };
        "Custom Loader" = {
          active = true;
          "Choose Loader" = {
            value = "Loading Buddy";
            components = {
              "Custom Image" = "Custom Loader/images/loadingbuddy.gif";
            };
          };
          "Fullscreen" = "No";
          "Custom Image Scale" = "0";
          "Custom Image Location For Small GIFs" = "Center";
          "Change Background Color" = {
            value = "No";
            components = {
              "Background Color" = "#000000";
            };
          };
        };
        "Ethernet Icon" = {
          active = true;
          "Icon Style" = "KDE Plasma";
          "Icon Color" = {
            value = "White";
            components = {
              "Icon Color" = "#FFFFFF";
            };
          };
          "Focused Icon Color" = {
            value = "Black";
            components = {
              "Icon Color" = "#FFFFFF";
            };
          };
        };
        "Outrun Theme" = {
          active = true;
          "Footer Border" = "Yes";
          "Game Shadow" = "Yes";
          "Button Colors" = "Yes";
          "Font" = "None";
          "Theme Color 1" = "Cyan";
          "Theme Color 2" = "Green";
        };
        "QAM Hide Tabs" = {
          active = true;
          "Remote Play Together" = "Yes";
          "Notifications" = "Yes";
          "Friends" = "Yes";
          "Settings" = "Yes";
          "Performance" = "Yes";
          "Soundtrack" = "No";
          "Help" = "No";
          "Keyboard" = "Yes";
        };
        "Remove Broadcasts" = {
          active = true;
        };
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
    };
    "SDH-AudioLoader" = pkgs.decky-audio-loader;
    "decky-steamgriddb" = pkgs.decky-steamgriddb;
    "decky-protondb" = pkgs.decky-protondb;
    "decky-isthereanydeal" = pkgs.decky-isthereanydeal;
    "decky-brightness-bar" = pkgs.decky-brightness-bar;
    "decky-autoflatpaks" = pkgs.decky-autoflatpaks;
    "decky-autosuspend" = pkgs.decky-autosuspend;
    "decky-Bluetooth" = pkgs.decky-bluetooth;
    "decky-tabmaster" = pkgs.decky-tabmaster;
    "decky-syncthing" = pkgs.decky-syncthing;
    "decky-kdeconnect" = pkgs.decky-kdeconnect;
    "decky-web-browser" = pkgs.decky-web-browser;
    "decky-lookup" = pkgs.decky-lookup;
    "decky-museck" = pkgs.decky-museck;
    "decky-free-loader" = pkgs.decky-free-loader;
  };
}
