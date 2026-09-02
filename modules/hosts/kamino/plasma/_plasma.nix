# Kamino-only Plasma settings and keys whose value differs from the shared
# base (modules/home/plasma/_plasma.nix). Imported by ../plasma.nix as a bare
# programs.plasma attrset; merged over the base by the module system.
{
  shortcuts = {
    ActivityManager.switch-to-activity-d8f8a80b-ef28-40cf-9f6d-853de37c96b3 = [ ];
    Clementine.next_album = "Shift+Media Next";
    Clementine.next_track = [ ];
    Clementine.play_pause = [ ];
    Clementine.prev_track = [ ];
    Clementine.stop = [ ];
    "KDE Keyboard Layout Switcher"."Switch keyboard layout to English (US)" = [ ];
    kwin.Expose = "Ctrl+F9";
    kwin.ExposeAll = [
      "Launch (C)"
      "Ctrl+F10"
    ];
    kwin.ExposeClass = "Ctrl+F7";
    kwin."Move Tablet to Next Output" = [ ];
    kwin."Switch to Desktop 1" = "Ctrl+F1";
    kwin."Switch to Desktop 2" = "Ctrl+F2";
    kwin."Switch to Desktop 3" = "Ctrl+F3";
    kwin."Switch to Desktop 4" = "Ctrl+F4";
    kwin."Walk Through Windows" = "Alt+Tab";
    kwin."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
    kwin."Walk Through Windows of Current Application" = "Alt+`";
    kwin."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
    kwin."Window Shade" = [ ];
    plasmashell."stop current activity" = "Meta+S";
    "services/org.kde.spectacle.desktop".CurrentMonitorScreenShot = [ ];
    "services/org.kde.spectacle.desktop".OpenWithoutScreenshot = [ ];
  };
  configFile = {
    baloofilerc.General."exclude filters" =
      "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
    baloofilerc.General."exclude filters version" = 9;
    dolphinrc.ExtractDialog."1920x1080 screen: Height" = 540;
    dolphinrc.ExtractDialog."1920x1080 screen: Width" = 1280;
    dolphinrc.ExtractDialog."DirHistory[$e]" = "$HOME/SteamPipe/Stardew Valley/Mods/";
    dolphinrc.General.ViewPropsTimestamp = "2025,3,25,17,5,26.724";
    dolphinrc.IconsMode.PreviewSize = 256;
    kactivitymanagerdrc.activities.d8f8a80b-ef28-40cf-9f6d-853de37c96b3 = "Default";
    kcminputrc."Libinput/1267/10848/ELAN2513:00 04F3:2A60".Enabled = false;
    kcminputrc."Libinput/1739/52745/SYNA30B4:00 06CB:CE09".NaturalScroll = true;
    kdeglobals.General.XftAntialias = true;
    kdeglobals.General.XftHintStyle = "hintslight";
    kdeglobals.General.XftSubPixel = "none";
    kdeglobals.General.fixed = "CaskaydiaCove Nerd Font Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    kdeglobals.General.font = "CaskaydiaCove Nerd Font Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    kdeglobals.General.menuFont = "CaskaydiaCove Nerd Font Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    kdeglobals.General.smallestReadableFont = "CaskaydiaCove Nerd Font Mono,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    kdeglobals.General.toolBarFont = "CaskaydiaCove Nerd Font Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    kdeglobals."KFileDialog Settings"."Speedbar Width" = 157;
    kdeglobals."KShortcutsDialog Settings"."Dialog Size" = "600,480";
    kdeglobals.WM.activeBackground = "28,32,47";
    kdeglobals.WM.activeBlend = "28,32,47";
    kdeglobals.WM.activeFont = "CaskaydiaCove Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
    kdeglobals.WM.activeForeground = "211,218,227";
    kdeglobals.WM.inactiveBackground = "34,39,57";
    kdeglobals.WM.inactiveBlend = "28,32,47";
    kdeglobals.WM.inactiveForeground = "141,147,159";
    kscreenlockerrc.Daemon.LockGrace = 30;
    kscreenlockerrc.Daemon.Timeout = 15;
    kscreenlockerrc.Greeter.WallpaperPlugin = "org.kde.slideshow";
    kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".Image =
      "/nix/store/bf8pazbx04wkj9p7xqnjvs73jh4hvk3y-plasma-workspace-wallpapers-6.3.3/share/wallpapers/Elarun/";
    kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".PreviewImage =
      "/nix/store/bf8pazbx04wkj9p7xqnjvs73jh4hvk3y-plasma-workspace-wallpapers-6.3.3/share/wallpapers/Elarun/";
    kscreenlockerrc."Greeter/Wallpaper/org.kde.slideshow/General".SlidePaths =
      "/nix/store/k80n2pbyrybk7q3hqi8hvahfmaq14d39-breeze-6.6.5/share/wallpapers/,/run/current-system/sw/share/wallpapers/,/home/sam/gen_sync/HQ Wallpapers/,/home/sam/gen_sync/Megastructures Wallpapers/";
    kwalletrc.Wallet."Launch Manager" = true;
    kwalletrc.Wallet."Leave Open" = true;
    kwinrc.Desktops.Id_1 = "b4b3ea4b-493b-42a7-83c7-05480f303f45";
    kwinrc.Effect-wobblywindows.Drag = 97;
    kwinrc.Effect-wobblywindows.MoveFactor = 25;
    kwinrc.Effect-wobblywindows.Stiffness = 1;
    kwinrc.Effect-wobblywindows.WobblynessLevel = 4;
    kwinrc.NightColor.Active = true;
    kwinrc.Plugins.glideEnabled = true;
    kwinrc.Plugins.magiclampEnabled = true;
    kwinrc.Plugins.scaleEnabled = false;
    kwinrc.Plugins.squashEnabled = false;
    kwinrc.Plugins.translucencyEnabled = true;
    kwinrc."Tiling/2df8aa8b-ea92-50fb-991c-0756e2a9e0de".tiles =
      "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
    kwinrc."Tiling/b4b3ea4b-493b-42a7-83c7-05480f303f45/676c8056-dc17-4221-9cf6-d8d25327abe2".tiles =
      "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
    kwinrc."Tiling/b4b3ea4b-493b-42a7-83c7-05480f303f45/d008e027-12a6-47e0-8f73-88376f4dae2f".padding =
      4;
    kwinrc."Tiling/b4b3ea4b-493b-42a7-83c7-05480f303f45/d008e027-12a6-47e0-8f73-88376f4dae2f".tiles =
      "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
    kwinrc."Tiling/b4b3ea4b-493b-42a7-83c7-05480f303f45/eb041008-1f88-4344-a486-c28d76b578d7".tiles =
      "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
    kwinrc."Tiling/b4b3ea4b-493b-42a7-83c7-05480f303f45/fb1ceae5-14df-4b02-aee3-7def7fe49f68".padding =
      4;
    kwinrc."Tiling/b4b3ea4b-493b-42a7-83c7-05480f303f45/fb1ceae5-14df-4b02-aee3-7def7fe49f68".tiles =
      "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
    kxkbrc.Layout.VariantList = "dvorak,";
    plasmanotifyrc."Applications/com.usebottles.bottles".Seen = true;
    plasmanotifyrc."Applications/dev.deedles.Trayscale".Seen = true;
    plasmanotifyrc."Applications/discord".Seen = true;
    plasmaparc.General.GlobalMute = true;
    plasmaparc.General.GlobalMuteSinks = true;
    plasmaparc.General.GlobalMuteSinksMutedDevices = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI3__sink.0,alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI2__sink.0,alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI1__sink.0,alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink.0";
    plasmaparc.General.GlobalMuteSources = true;
    plasmaparc.General.GlobalMuteSourcesMutedDevices = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic2__source.0,alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source.0";
    spectaclerc.ImageSave.lastImageSaveLocation = "file:///home/sam/Pictures/Screenshots/Screenshot_20260825_224255.png";
  };
}
