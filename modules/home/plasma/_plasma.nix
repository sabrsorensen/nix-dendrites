{ inputs, ... }:
let
  homeModule =
    { ... }:
    {
      programs.plasma = {
        enable = true;
        shortcuts = {
          ActivityManager.switch-to-activity-68c5accc-a888-40e6-a162-4a62c7fba185 = [ ];
          "KDE Keyboard Layout Switcher"."Switch keyboard layout to English (Dvorak)" = [ ];
          "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
          "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Ctrl+Shift";
          kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
          kmix.decrease_microphone_volume = "Microphone Volume Down";
          kmix.decrease_volume = "Volume Down";
          kmix.decrease_volume_small = "Shift+Volume Down";
          kmix.increase_microphone_volume = "Microphone Volume Up";
          kmix.increase_volume = "Volume Up";
          kmix.increase_volume_small = "Shift+Volume Up";
          kmix.mic_mute = [
            "Microphone Mute"
            "Meta+Volume Mute"
          ];
          kmix.mute = "Volume Mute";
          kmix.push_to_talk = [ ];
          ksmserver."Halt Without Confirmation" = [ ];
          ksmserver."Lock Session" = [
            "Screensaver"
            "Meta+L"
          ];
          ksmserver."Log Out" = "Ctrl+Alt+Del";
          ksmserver."Log Out Without Confirmation" = [ ];
          ksmserver.LogOut = [ ];
          ksmserver.Reboot = [ ];
          ksmserver."Reboot Without Confirmation" = [ ];
          ksmserver."Shut Down" = [ ];
          kwin."Activate Window Demanding Attention" = "Meta+Ctrl+A";
          kwin."Cycle Overview" = [ ];
          kwin."Cycle Overview Opposite" = [ ];
          kwin."Decrease Opacity" = [ ];
          kwin."Edit Tiles" = "Meta+T";
          kwin.Expose = [
            "Ctrl+F9"
            "Meta+F9"
          ];
          kwin.ExposeAll = [
            "Launch (C)"
            "Ctrl+F10"
            "Meta+F10"
          ];
          kwin.ExposeClass = [
            "Ctrl+F7"
            "Meta+F7"
          ];
          kwin.ExposeClassCurrentDesktop = [ ];
          kwin."Grid View" = "Meta+G";
          kwin."Increase Opacity" = [ ];
          kwin."Kill Window" = "Meta+Ctrl+Esc";
          kwin."Move Tablet to Next LogicalOutput" = [ ];
          kwin.MoveMouseToCenter = "Meta+F6";
          kwin.MoveMouseToFocus = "Meta+F5";
          kwin.MoveZoomDown = [ ];
          kwin.MoveZoomLeft = [ ];
          kwin.MoveZoomRight = [ ];
          kwin.MoveZoomUp = [ ];
          kwin.Overview = "Meta+W";
          kwin."Setup Window Shortcut" = [ ];
          kwin."Show Desktop" = "Meta+D";
          kwin."Switch One Desktop Down" = "Meta+Ctrl+Down";
          kwin."Switch One Desktop Up" = "Meta+Ctrl+Up";
          kwin."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
          kwin."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
          kwin."Switch Window Down" = "Meta+Alt+Down";
          kwin."Switch Window Left" = "Meta+Alt+Left";
          kwin."Switch Window Right" = "Meta+Alt+Right";
          kwin."Switch Window Up" = "Meta+Alt+Up";
          kwin."Switch to Desktop 1" = [
            "Ctrl+F1"
            "Meta+F1"
          ];
          kwin."Switch to Desktop 10" = [ ];
          kwin."Switch to Desktop 11" = [ ];
          kwin."Switch to Desktop 12" = [ ];
          kwin."Switch to Desktop 13" = [ ];
          kwin."Switch to Desktop 14" = [ ];
          kwin."Switch to Desktop 15" = [ ];
          kwin."Switch to Desktop 16" = [ ];
          kwin."Switch to Desktop 17" = [ ];
          kwin."Switch to Desktop 18" = [ ];
          kwin."Switch to Desktop 19" = [ ];
          kwin."Switch to Desktop 2" = [
            "Ctrl+F2"
            "Meta+F2"
          ];
          kwin."Switch to Desktop 20" = [ ];
          kwin."Switch to Desktop 21" = [ ];
          kwin."Switch to Desktop 22" = [ ];
          kwin."Switch to Desktop 23" = [ ];
          kwin."Switch to Desktop 24" = [ ];
          kwin."Switch to Desktop 25" = [ ];
          kwin."Switch to Desktop 3" = [
            "Ctrl+F3"
            "Meta+F3"
          ];
          kwin."Switch to Desktop 4" = [
            "Ctrl+F4"
            "Meta+F4"
          ];
          kwin."Switch to Desktop 5" = [ ];
          kwin."Switch to Desktop 6" = [ ];
          kwin."Switch to Desktop 7" = [ ];
          kwin."Switch to Desktop 8" = [ ];
          kwin."Switch to Desktop 9" = [ ];
          kwin."Switch to Next Desktop" = [ ];
          kwin."Switch to Next Screen" = [ ];
          kwin."Switch to Previous Desktop" = [ ];
          kwin."Switch to Previous Screen" = [ ];
          kwin."Switch to Screen 0" = [ ];
          kwin."Switch to Screen 1" = [ ];
          kwin."Switch to Screen 2" = [ ];
          kwin."Switch to Screen 3" = [ ];
          kwin."Switch to Screen 4" = [ ];
          kwin."Switch to Screen 5" = [ ];
          kwin."Switch to Screen 6" = [ ];
          kwin."Switch to Screen 7" = [ ];
          kwin."Switch to Screen Above" = [ ];
          kwin."Switch to Screen Below" = [ ];
          kwin."Switch to Screen to the Left" = [ ];
          kwin."Switch to Screen to the Right" = [ ];
          kwin."Toggle Night Color" = [ ];
          kwin."Toggle Window Raise/Lower" = [ ];
          kwin."Walk Through Windows" = [
            "Alt+Tab"
            "Meta+Tab"
          ];
          kwin."Walk Through Windows (Reverse)" = [
            "Alt+Shift+Tab"
            "Meta+Shift+Tab"
          ];
          kwin."Walk Through Windows Alternative" = [ ];
          kwin."Walk Through Windows Alternative (Reverse)" = [ ];
          kwin."Walk Through Windows of Current Application" = [
            "Alt+`"
            "Meta+`"
          ];
          kwin."Walk Through Windows of Current Application (Reverse)" = [
            "Alt+~"
            "Meta+~"
          ];
          kwin."Walk Through Windows of Current Application Alternative" = [ ];
          kwin."Walk Through Windows of Current Application Alternative (Reverse)" = [ ];
          kwin."Window Above Other Windows" = [ ];
          kwin."Window Below Other Windows" = [ ];
          kwin."Window Close" = "Alt+F4";
          kwin."Window Custom Quick Tile Bottom" = [ ];
          kwin."Window Custom Quick Tile Left" = [ ];
          kwin."Window Custom Quick Tile Right" = [ ];
          kwin."Window Custom Quick Tile Top" = [ ];
          kwin."Window Fullscreen" = [ ];
          kwin."Window Grow Horizontal" = [ ];
          kwin."Window Grow Vertical" = [ ];
          kwin."Window Lower" = [ ];
          kwin."Window Maximize" = "Meta+PgUp";
          kwin."Window Maximize Horizontal" = [ ];
          kwin."Window Maximize Vertical" = [ ];
          kwin."Window Minimize" = "Meta+PgDown";
          kwin."Window Move" = [ ];
          kwin."Window Move Center" = [ ];
          kwin."Window No Border" = [ ];
          kwin."Window On All Desktops" = [ ];
          kwin."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
          kwin."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
          kwin."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
          kwin."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
          kwin."Window One Screen Down" = [ ];
          kwin."Window One Screen Up" = [ ];
          kwin."Window One Screen to the Left" = [ ];
          kwin."Window One Screen to the Right" = [ ];
          kwin."Window Operations Menu" = "Alt+F3";
          kwin."Window Pack Down" = [ ];
          kwin."Window Pack Left" = [ ];
          kwin."Window Pack Right" = [ ];
          kwin."Window Pack Up" = [ ];
          kwin."Window Quick Tile Bottom" = "Meta+Down";
          kwin."Window Quick Tile Bottom Left" = [ ];
          kwin."Window Quick Tile Bottom Right" = [ ];
          kwin."Window Quick Tile Left" = "Meta+Left";
          kwin."Window Quick Tile Right" = "Meta+Right";
          kwin."Window Quick Tile Top" = "Meta+Up";
          kwin."Window Quick Tile Top Left" = [ ];
          kwin."Window Quick Tile Top Right" = [ ];
          kwin."Window Raise" = [ ];
          kwin."Window Resize" = [ ];
          kwin."Window Restore" = "Meta+Backspace";
          kwin."Window Shrink Horizontal" = [ ];
          kwin."Window Shrink Vertical" = [ ];
          kwin."Window to Desktop 1" = [ ];
          kwin."Window to Desktop 10" = [ ];
          kwin."Window to Desktop 11" = [ ];
          kwin."Window to Desktop 12" = [ ];
          kwin."Window to Desktop 13" = [ ];
          kwin."Window to Desktop 14" = [ ];
          kwin."Window to Desktop 15" = [ ];
          kwin."Window to Desktop 16" = [ ];
          kwin."Window to Desktop 17" = [ ];
          kwin."Window to Desktop 18" = [ ];
          kwin."Window to Desktop 19" = [ ];
          kwin."Window to Desktop 2" = [ ];
          kwin."Window to Desktop 20" = [ ];
          kwin."Window to Desktop 21" = [ ];
          kwin."Window to Desktop 22" = [ ];
          kwin."Window to Desktop 23" = [ ];
          kwin."Window to Desktop 24" = [ ];
          kwin."Window to Desktop 25" = [ ];
          kwin."Window to Desktop 3" = [ ];
          kwin."Window to Desktop 4" = [ ];
          kwin."Window to Desktop 5" = [ ];
          kwin."Window to Desktop 6" = [ ];
          kwin."Window to Desktop 7" = [ ];
          kwin."Window to Desktop 8" = [ ];
          kwin."Window to Desktop 9" = [ ];
          kwin."Window to Next Desktop" = [ ];
          kwin."Window to Next Screen" = "Meta+Shift+Right";
          kwin."Window to Previous Desktop" = [ ];
          kwin."Window to Previous Screen" = "Meta+Shift+Left";
          kwin."Window to Screen 0" = [ ];
          kwin."Window to Screen 1" = [ ];
          kwin."Window to Screen 2" = [ ];
          kwin."Window to Screen 3" = [ ];
          kwin."Window to Screen 4" = [ ];
          kwin."Window to Screen 5" = [ ];
          kwin."Window to Screen 6" = [ ];
          kwin."Window to Screen 7" = [ ];
          kwin.disableInputCapture = "Meta+Shift+Esc";
          kwin.view_actual_size = "Meta+0";
          kwin.view_zoom_in = [
            "Meta++"
            "Meta+="
          ];
          kwin.view_zoom_out = "Meta+-";
          mediacontrol.mediavolumedown = [ ];
          mediacontrol.mediavolumeup = [ ];
          mediacontrol.nextmedia = "Media Next";
          mediacontrol.pausemedia = "Media Pause";
          mediacontrol.playmedia = [ ];
          mediacontrol.playpausemedia = "Media Play";
          mediacontrol.previousmedia = "Media Previous";
          mediacontrol.seekbackwardmedia = "Media Rewind";
          mediacontrol.seekbackwardmedialong = [ ];
          mediacontrol.seekforwardmedia = "Media Fast Forward";
          mediacontrol.seekforwardmedialong = [ ];
          mediacontrol.stopmedia = "Media Stop";
          org_kde_powerdevil."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
          org_kde_powerdevil."Decrease Screen Brightness" = "Monitor Brightness Down";
          org_kde_powerdevil."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
          org_kde_powerdevil.Hibernate = "Hibernate";
          org_kde_powerdevil."Increase Keyboard Brightness" = "Keyboard Brightness Up";
          org_kde_powerdevil."Increase Screen Brightness" = "Monitor Brightness Up";
          org_kde_powerdevil."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
          org_kde_powerdevil.PowerDown = "Power Down";
          org_kde_powerdevil.PowerOff = "Power Off";
          org_kde_powerdevil.Sleep = "Sleep";
          org_kde_powerdevil."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
          org_kde_powerdevil."Turn Off Screen" = [ ];
          org_kde_powerdevil.powerProfile = [
            "Battery"
            "Meta+B"
          ];
          plasmashell."Slideshow Wallpaper Next Image" = [ ];
          plasmashell."activate application launcher" = [
            "Meta"
            "Alt+F1"
          ];
          plasmashell."activate task manager entry 1" = "Meta+1";
          plasmashell."activate task manager entry 10" = [ ];
          plasmashell."activate task manager entry 2" = "Meta+2";
          plasmashell."activate task manager entry 3" = "Meta+3";
          plasmashell."activate task manager entry 4" = "Meta+4";
          plasmashell."activate task manager entry 5" = "Meta+5";
          plasmashell."activate task manager entry 6" = "Meta+6";
          plasmashell."activate task manager entry 7" = "Meta+7";
          plasmashell."activate task manager entry 8" = "Meta+8";
          plasmashell."activate task manager entry 9" = "Meta+9";
          plasmashell."clear history" = [ ];
          plasmashell.clear-history = [ ];
          plasmashell.clipboard_action = "Meta+Ctrl+X";
          plasmashell.cycle-panels = "Meta+Alt+P";
          plasmashell.cycleNextAction = [ ];
          plasmashell.cyclePrevAction = [ ];
          plasmashell.edit_clipboard = [ ];
          plasmashell."manage activities" = "Meta+Q";
          plasmashell."next activity" = "Meta+A";
          plasmashell."previous activity" = "Meta+Shift+A";
          plasmashell.repeat_action = [ ];
          plasmashell."show dashboard" = "Ctrl+F12";
          plasmashell.show-barcode = [ ];
          plasmashell.show-on-mouse-pos = "Meta+V";
          plasmashell."switch to next activity" = [ ];
          plasmashell."switch to previous activity" = [ ];
          plasmashell."toggle do not disturb" = [ ];
        };
        configFile = {
          baloofilerc.General.dbVersion = 2;
          dolphinrc.DetailsMode.ExpandableFolders = false;
          dolphinrc.General.GlobalViewProps = false;
          dolphinrc.General.ViewPropsTimestamp = "2026,3,11,12,43,3.685";
          dolphinrc."KFileDialog Settings"."Places Icons Auto-resize" = false;
          dolphinrc."KFileDialog Settings"."Places Icons Static Size" = 22;
          dolphinrc.PreviewSettings.Plugins = "appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,directorythumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,opendocumentthumbnail,svgthumbnail,windowsexethumbnail,windowsimagethumbnail,fontthumbnail,blenderthumbnail,ffmpegthumbs,gsthumbnail,mobithumbnail,rawthumbnail";
          kactivitymanagerdrc.activities."68c5accc-a888-40e6-a162-4a62c7fba185" = "Default";
          kcminputrc."Libinput/1267/11299/ELAN9009:00 04F3:2C23".Enabled = false;
          kcminputrc."Libinput/1267/11299/ELAN9009:00 04F3:2C23 Touchpad".Enabled = true;
          kcminputrc."Libinput/1267/11350/ELAN9008:00 04F3:2C56".Enabled = false;
          kcminputrc."Libinput/1267/12545/ASUE1406:00 04F3:3101 Touchpad".Enabled = true;
          kcminputrc."Libinput/1267/12545/ASUE1406:00 04F3:3101 Touchpad".NaturalScroll = true;
          kded5rc.Module-browserintegrationreminder.autoload = false;
          kded5rc.Module-device_automounter.autoload = false;
          kdeglobals.KDE.contrast = 4;
          kdeglobals.KDE.frameContrast = 0.2;
          kdeglobals."KFileDialog Settings"."Allow Expansion" = false;
          kdeglobals."KFileDialog Settings"."Automatically select filename extension" = true;
          kdeglobals."KFileDialog Settings"."Breadcrumb Navigation" = true;
          kdeglobals."KFileDialog Settings"."Decoration position" = 2;
          kdeglobals."KFileDialog Settings"."Show Full Path" = false;
          kdeglobals."KFileDialog Settings"."Show Inline Previews" = true;
          kdeglobals."KFileDialog Settings"."Show Preview" = false;
          kdeglobals."KFileDialog Settings"."Show Speedbar" = true;
          kdeglobals."KFileDialog Settings"."Show hidden files" = false;
          kdeglobals."KFileDialog Settings"."Sort by" = "Date";
          kdeglobals."KFileDialog Settings"."Sort directories first" = true;
          kdeglobals."KFileDialog Settings"."Sort hidden files last" = false;
          kdeglobals."KFileDialog Settings"."Sort reversed" = false;
          kdeglobals."KFileDialog Settings"."Speedbar Width" = 140;
          kdeglobals."KFileDialog Settings"."View Style" = "DetailTree";
          kdeglobals.PreviewSettings.EnableRemoteFolderThumbnail = false;
          kdeglobals.PreviewSettings.MaximumRemoteSize = 0;
          kdeglobals.WM.activeBackground = "39,44,49";
          kdeglobals.WM.activeBlend = "252,252,252";
          kdeglobals.WM.activeForeground = "252,252,252";
          kdeglobals.WM.inactiveBackground = "32,36,40";
          kdeglobals.WM.inactiveBlend = "161,169,177";
          kdeglobals.WM.inactiveForeground = "161,169,177";
          kiorc.Confirmations.ConfirmDelete = true;
          kiorc.Confirmations.ConfirmEmptyTrash = true;
          kiorc.Confirmations.ConfirmTrash = false;
          kiorc."Executable scripts".behaviourOnLaunch = "alwaysAsk";
          ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".Days = 7;
          ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".LimitReachedAction = 0;
          ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".Percent = 10;
          ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".UseSizeLimit = true;
          ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".UseTimeLimit = false;
          kwalletrc.Wallet."Close When Idle" = false;
          kwalletrc.Wallet."Close on Screensaver" = false;
          kwalletrc.Wallet."Default Wallet" = "kdewallet";
          kwalletrc.Wallet.Enabled = true;
          kwalletrc.Wallet."First Use" = false;
          kwalletrc.Wallet."Idle Timeout" = 10;
          kwalletrc.Wallet."Launch Manager" = false;
          kwalletrc.Wallet."Leave Manager Open" = false;
          kwalletrc.Wallet."Leave Open" = false;
          kwalletrc.Wallet."Prompt on Open" = false;
          kwalletrc.Wallet."Use One Wallet" = true;
          kwalletrc."org.freedesktop.secrets".apiEnabled = true;
          kwinrc.Desktops.Id_1 = "3efbb2a2-2a78-4fe1-b198-327e7ead932f";
          kwinrc.Desktops.Number = 1;
          kwinrc.Desktops.Rows = 1;
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/1872ecf7-cd50-4b35-961d-12325a7b9aaa".padding =
            4;
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/1872ecf7-cd50-4b35-961d-12325a7b9aaa".tiles =
            "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/18f5d6cb-e370-42dc-96a4-c724c2e44eca".padding =
            4;
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/18f5d6cb-e370-42dc-96a4-c724c2e44eca".tiles =
            "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/a5d10b9a-2d67-473f-a2ce-494714face14".padding =
            4;
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/a5d10b9a-2d67-473f-a2ce-494714face14".tiles =
            "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/a79cee2a-c3cc-4b6f-81da-a57d2ede6f6b".padding =
            4;
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/a79cee2a-c3cc-4b6f-81da-a57d2ede6f6b".tiles =
            "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/fac35e6c-f98e-48a1-9a4c-4a22987013f9".padding =
            4;
          kwinrc."Tiling/3efbb2a2-2a78-4fe1-b198-327e7ead932f/fac35e6c-f98e-48a1-9a4c-4a22987013f9".tiles =
            "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
          kwinrc.Xwayland.Scale = 1;
          kwinrulesrc.General.rules = "";
          kxkbrc.Layout.DisplayNames = ",";
          kxkbrc.Layout.LayoutList = "us,us";
          kxkbrc.Layout.Use = true;
          kxkbrc.Layout.VariantList = ",dvorak";
          plasma-localerc.Formats.LANG = "en_US.UTF-8";
          plasmanotifyrc."Applications/ferdium".Seen = true;
          plasmanotifyrc."Applications/firefox".Seen = true;
          plasmanotifyrc."Applications/signal".Seen = true;
          plasmarc.Wallpapers.usersWallpapers = "";
          spectaclerc.ImageSave.lastImageSaveLocation = "file:///home/sam/Pictures/Screenshots/Screenshot_20260610_144245.png";
          spectaclerc.ImageSave.translatedScreenshotsFolder = "Screenshots";
          spectaclerc.VideoSave.translatedScreencastsFolder = "Screencasts";
        };
      };
    };
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.plasma = lib.mkEnableOption "Plasma Manager declarative KDE Plasma configuration";
      imports = [ inputs.plasma-manager.homeModules.plasma-manager ];
      config = lib.mkIf config.my.features.plasma (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.plasma = featureModule;

  flake.modules.nixos.plasma =
    { lib, ... }:
    {
      options.my.host.features.plasma =
        lib.mkEnableOption "Plasma Manager declarative KDE Plasma configuration";
    };
}
