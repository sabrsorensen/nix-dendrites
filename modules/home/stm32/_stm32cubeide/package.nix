# Vendored from https://git.sr.ht/~shelvacu/stm32cubeide-nix (CC0, last
# upstream commit 458ac9e, 2025-08-21, packaging 1.19.0) and bumped to 2.2.0.
# The IDE is extracted, not built: the installer is a Makeself 2.3.0 archive
# whose payload tarball is unpacked and autoPatchelf'd in place.
{
  lib,
  stdenv,
  requireFile,
  runCommand,
  gnugrep,
  unzip,
  makeWrapper,
  autoPatchelfHook,
  swt,

  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libGL,
  libudev0-shim,
  libxkbcommon,
  libgbm,
  nspr,
  nss,
  pango,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxxf86vm,
  libxcb-wm,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libgcrypt,
  openssl,
  udev,
  ncurses5,
  ffmpeg_7,
  ffmpeg_6,
  ffmpeg_4,
  pcsclite,
  krb5,
  kdePackages,
  gsettings-desktop-schemas,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "stm32cubeide";
  version = "2.2.0";

  src = finalAttrs.passthru.extracted;

  passthru = {
    # ST gates the download, so this has to be added to the store by hand:
    # download the generic Linux installer (not the Deb/RPM ones) from the URL
    # below and run `nix-store --add-fixed sha256 <file>`.
    zip = requireFile {
      name = "stm32cubeide_${finalAttrs.version}-Lin-x86_64.sh.zip";
      url = "https://www.st.com/en/development-tools/stm32cubeide.html#get-software";
      hash = "sha256-ajSAgU9xj9Bd1DzWwvTMuXVWJzAp+rOmBbDcNHQpEdA=";
      hashMode = "flat";
    };
    extracted =
      runCommand "${finalAttrs.pname}-src-extracted"
        {
          nativeBuildInputs = [
            gnugrep
            unzip
            ./extract_makeself.bash
          ];
        }
        ''
          (
            set -euo pipefail
            zip=${lib.escapeShellArg finalAttrs.passthru.zip}
            declare fileList
            fileList="$(unzip -Z -1 "$zip")"
            declare -i countFiles
            countFiles="$(printf '%s\n' "$fileList" | wc -l)"
            if [[ $countFiles != 1 ]]; then
              echo "Error: Expected exactly 1 file in the zip, but there were $countFiles files" >&2
              exit 1
            fi

            unzip -p "$zip" > installer.sh
            mkdir -p "$out"
            extract_makeself "$out" installer.sh
          )
        '';
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libGL
    libudev0-shim
    libxkbcommon
    libgbm
    nspr
    nss
    pango
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
    libxxf86vm
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libgcrypt
    openssl
    udev
    ncurses5
    ffmpeg_7
    ffmpeg_6
    ffmpeg_4
    pcsclite
    krb5
    kdePackages.qtwayland
    swt
    gsettings-desktop-schemas
  ];

  strictDeps = true;

  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;
  installPhase = ''
    runHook preInstall

    mainDir="$out"/share/stm32cubeide
    mkdir -p "$mainDir"
    tar -xf stm32cubeide_*.tar.gz -C "$mainDir"

    # The desktop entry Execs stm32cubeide_wayland, which just forces
    # GDK_BACKEND=x11 and runs the (wrapped) stm32cubeide beside it.
    bash ./desktop_shortcut.sh ${
      lib.escapeShellArg (finalAttrs.version + "-nix")
    } "$mainDir" "$out"/share/applications/st-stm32cubeide-${finalAttrs.version}.desktop

    # --argv0 keeps the Eclipse launcher finding stm32cubeide.ini next to the
    # real binary. Java prefs and SWT's native libs are redirected away from
    # the read-only store.
    wrapProgram "$mainDir/stm32cubeide" \
      --argv0 "$mainDir/stm32cubeide" \
      --set GDK_BACKEND x11 \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --run 'xdgConfigDir="''${XDG_CONFIG_HOME:-"$HOME"/.config}"' \
      --run 'cubeConfigDir="$xdgConfigDir/stm32cubeide-nix"' \
      --run 'mkdir -p "$cubeConfigDir"/{system/.systemPrefs,user}' \
      --run 'touch "$cubeConfigDir/system/.systemPrefs/.system.lock"' \
      --run 'export JAVA_TOOL_OPTIONS="''${JAVA_TOOL_OPTIONS:-} -Djava.util.prefs.systemRoot=$cubeConfigDir/system -Djava.util.prefs.userRoot=$cubeConfigDir/user -Dswt.library.path=${swt}/lib"'

    binDir="$out"/bin
    mkdir -p "$binDir"
    ln -s "$mainDir/stm32cubeide" "$binDir/stm32cubeide"
    # Same flags as the bundled headless-build.sh.
    makeWrapper "$mainDir/stm32cubeide" "$binDir/stm32cubeide-headless-build" \
      --add-flags '--launcher.suppressErrors -nosplash -application org.eclipse.cdt.managedbuilder.core.headlessbuild'

    # JNA bundles libjnidispatch for every OS/arch; only ours is ever loaded,
    # and the rest (e.g. dragonflybsd-x86-64, wanting libc.so.8) can't be
    # patched.
    find "$mainDir"/plugins/com.sun.jna_*/com/sun/jna -mindepth 1 -maxdepth 1 -type d \
      ! -name linux-x86-64 -exec rm -r {} +

    addAutoPatchelfSearchPath "$mainDir"
    # libQt6WaylandEglClientHwIntegration is wanted only by the bundled
    # CubeProgrammer's EGL-on-Wayland Qt platform plugin; nixpkgs' Qt 6.11
    # folded it into qtbase, so Qt falls back to another platform plugin.
    ignoreMissingDepsArray+=(
      libav{codec,format}.so.{54,56,57,59}
      libav{codec,format}-ffmpeg.so.56
      libxerces-c-3.2.so
      libQt6WaylandEglClientHwIntegration.so.6
    )

    runHook postInstall
  '';

  meta = {
    description = "STMicroelectronics' Eclipse-based IDE for STM32 microcontrollers";
    homepage = "https://www.st.com/en/development-tools/stm32cubeide.html";
    mainProgram = "stm32cubeide";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
})
