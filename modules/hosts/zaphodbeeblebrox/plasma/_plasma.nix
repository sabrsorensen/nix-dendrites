# Zaphod-only Plasma settings and keys whose value differs from the shared
# base (modules/home/plasma/_plasma.nix). Imported by ../plasma.nix as a bare
# programs.plasma attrset; merged over the base by the module system.
{
  shortcuts = {
    ActivityManager.switch-to-activity-68c5accc-a888-40e6-a162-4a62c7fba185 = [ ];
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
    kwin."Switch to Desktop 1" = [
      "Ctrl+F1"
      "Meta+F1"
    ];
    kwin."Switch to Desktop 2" = [
      "Ctrl+F2"
      "Meta+F2"
    ];
    kwin."Switch to Desktop 3" = [
      "Ctrl+F3"
      "Meta+F3"
    ];
    kwin."Switch to Desktop 4" = [
      "Ctrl+F4"
      "Meta+F4"
    ];
    kwin."Walk Through Windows" = [
      "Alt+Tab"
      "Meta+Tab"
    ];
    kwin."Walk Through Windows (Reverse)" = [
      "Alt+Shift+Tab"
      "Meta+Shift+Tab"
    ];
    kwin."Walk Through Windows of Current Application" = [
      "Alt+`"
      "Meta+`"
    ];
    kwin."Walk Through Windows of Current Application (Reverse)" = [
      "Alt+~"
      "Meta+~"
    ];
  };
  configFile = {
    dolphinrc.DetailsMode.ExpandableFolders = false;
    dolphinrc.General.GlobalViewProps = false;
    dolphinrc.General.ViewPropsTimestamp = "2026,3,11,12,43,3.685";
    dolphinrc.PreviewSettings.Plugins = "appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,directorythumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,opendocumentthumbnail,svgthumbnail,windowsexethumbnail,windowsimagethumbnail,fontthumbnail,blenderthumbnail,ffmpegthumbs,gsthumbnail,mobithumbnail,rawthumbnail";
    kactivitymanagerdrc.activities."68c5accc-a888-40e6-a162-4a62c7fba185" = "Default";
    kcminputrc."Libinput/1267/11299/ELAN9009:00 04F3:2C23".Enabled = false;
    kcminputrc."Libinput/1267/11299/ELAN9009:00 04F3:2C23 Touchpad".Enabled = true;
    kcminputrc."Libinput/1267/11350/ELAN9008:00 04F3:2C56".Enabled = false;
    kcminputrc."Libinput/1267/12545/ASUE1406:00 04F3:3101 Touchpad".Enabled = true;
    kcminputrc."Libinput/1267/12545/ASUE1406:00 04F3:3101 Touchpad".NaturalScroll = true;
    kdeglobals.KDE.contrast = 4;
    kdeglobals.KDE.frameContrast = 0.2;
    kdeglobals."KFileDialog Settings"."Speedbar Width" = 140;
    kdeglobals.PreviewSettings.EnableRemoteFolderThumbnail = false;
    kdeglobals.PreviewSettings.MaximumRemoteSize = 0;
    kdeglobals.WM.activeBackground = "39,44,49";
    kdeglobals.WM.activeBlend = "252,252,252";
    kdeglobals.WM.activeForeground = "252,252,252";
    kdeglobals.WM.inactiveBackground = "32,36,40";
    kdeglobals.WM.inactiveBlend = "161,169,177";
    kdeglobals.WM.inactiveForeground = "161,169,177";
    kiorc.Confirmations.ConfirmEmptyTrash = true;
    kiorc.Confirmations.ConfirmTrash = false;
    kiorc."Executable scripts".behaviourOnLaunch = "alwaysAsk";
    ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".Days = 7;
    ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".LimitReachedAction = 0;
    ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".Percent = 10;
    ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".UseSizeLimit = true;
    ktrashrc."\\/home\\/sam\\/.local\\/share\\/Trash".UseTimeLimit = false;
    kwalletrc.Wallet."Launch Manager" = false;
    kwalletrc.Wallet."Leave Open" = false;
    kwinrc.Desktops.Id_1 = "3efbb2a2-2a78-4fe1-b198-327e7ead932f";
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
    kxkbrc.Layout.VariantList = ",dvorak";
    spectaclerc.ImageSave.lastImageSaveLocation = "file:///home/sam/Pictures/Screenshots/Screenshot_20260610_144245.png";
  };
}
