# Sweet Ambar Blue: the pieces the store.kde.org global theme (p/2157756)
# only references by name. Not in nixpkgs (the old `sweet` package was
# GTK-only and has been removed). Sources:
#   - EliverLara/Sweet `Ambar-Blue`: Kvantum theme, colour scheme, Aurorae
#     window decoration, Konsole scheme
#   - EliverLara/Sweet-kde `Ambar-Blue`: Plasma desktop theme
#   - EliverLara/Sweet `nova`: Sweet-cursors (prebuilt; absent from the
#     Ambar-Blue branch, identical across nova/dark-plasma-6/Ambar-Blue-Dark)
#   - EliverLara/Sweet-folders: folder-only icon themes (all colour variants)
#     that inherit candy-icons for everything else
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  desktopTheme = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet-kde";
    rev = "e8865ce93de520f9b1caf5a965fb2d68fed05370";
    hash = "sha256-/J7K63OVM2ixQz168emxAdwW8qPyFFtsePgLqaSHzjA=";
  };
  cursors = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet";
    rev = "46e3802d3f4d9e992f94264f1d834f5f9621c03b";
    hash = "sha256-rB6l1u12u+X2kgwKUJRLYuBu6Q+cq5/1Arp5dMILYcE=";
  };
  folders = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet-folders";
    rev = "40a5d36e50437901c7eaa1119bb9ae8006e2fe5c";
    hash = "sha256-Pb3xsNKM5yGT4uAUxrCds1JSSvU/whhTJcmqiM7EW+4=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "sweet-ambar-blue-kde";
  version = "0-unstable-2026-05-07";

  src = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet";
    rev = "df37b2fcc62f68046468c660699193be37221f50";
    hash = "sha256-D4saCMTbb9rdO+0EbAAXNveu+ZJo+3XWIK8C7EUeats=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/{Kvantum,color-schemes,aurorae/themes,konsole,plasma/desktoptheme,icons}
    cp -r kde/kvantum/Sweet-Ambar-Blue $out/share/Kvantum/
    cp kde/colorschemes/SweetAmbarBlue.colors $out/share/color-schemes/
    cp -r kde/aurorae/Sweet-ambar-blue $out/share/aurorae/themes/
    cp kde/konsole/Sweet-Ambar-Blue.colorscheme $out/share/konsole/

    cp -r ${desktopTheme} $out/share/plasma/desktoptheme/Sweet-Ambar-Blue
    chmod -R u+w $out/share/plasma/desktoptheme/Sweet-Ambar-Blue
    rm -rf $out/share/plasma/desktoptheme/Sweet-Ambar-Blue/{.github,.gitignore,LICENSE,README.md}

    cp -r ${cursors}/kde/cursors/Sweet-cursors $out/share/icons/
    cp -r ${folders}/Sweet-* $out/share/icons/
    runHook postInstall
  '';

  meta = {
    description = "Sweet Ambar Blue KDE theme (Kvantum, colours, Aurorae, Plasma, cursors, folder icons, Konsole)";
    homepage = "https://github.com/EliverLara/Sweet/tree/Ambar-Blue";
    # Sweet is GPL-3.0; the Sweet-kde desktop theme is CC BY-SA 4.0.
    license = [
      lib.licenses.gpl3Only
      lib.licenses.cc-by-sa-40
    ];
    platforms = lib.platforms.all;
  };
}
