{
  lib,
  pkgs,
  fetchSymless,
}:
# Synergy 3: Symless's prebuilt Electron app, its Node single-executable
# background service and the Qt `synergy-core`, unpacked untouched from the
# Arch package. Nothing is patchelf'd: the service is a Node SEA whose
# injected blob patchelf can corrupt, so every entry point runs inside an FHS
# environment instead. The service finds `synergy-core` and the GUI beside its
# own executable, so the unpacked tree can live anywhere in the store.
let
  version = "3.9.1";

  unpacked = pkgs.stdenvNoCC.mkDerivation {
    pname = "synergy3-unwrapped";
    inherit version;

    src = fetchSymless {
      product = "synergy-personal-v3";
      file = "synergy-${version}-linux-resolute-x86_64.pkg.tar.zst";
      hash = "sha256-+ctU4CTa59nihBY/FPBX3ddbl8f8jX5EdV6kuNm9hH8=";
    };

    nativeBuildInputs = [ pkgs.zstd ];

    dontConfigure = true;
    dontBuild = true;
    # Prebuilt binaries run from the FHS env as shipped.
    dontFixup = true;

    unpackPhase = ''
      runHook preUnpack
      mkdir src
      tar --zstd -xf "$src" -C src
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib" "$out/share"
      cp -a src/opt/Synergy "$out/lib/synergy3"
      cp -a src/usr/share/icons "$out/share/icons"
      runHook postInstall
    '';

    meta = {
      description = "Synergy 3 (unwrapped Symless package)";
      homepage = "https://symless.com/synergy";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };

  fhs = pkgs.buildFHSEnv {
    pname = "synergy3-fhs";
    inherit version;
    # Each wrapper below passes the program to run and its arguments.
    runScript = pkgs.writeShellScript "synergy3-exec" ''exec "$@"'';
    targetPkgs =
      p:
      [
        # synergy-core (Qt 6, libei for Wayland input emulation/capture)
        p.qt6.qtbase
        p.qt6.qtwayland
        p.libei
        p.openssl
        p.libxkbcommon
        p.libnotify
        p.glib
        # Electron GUI
        p.gtk3
        p.nss
        p.nspr
        p.atk
        p.at-spi2-atk
        p.at-spi2-core
        p.cups
        p.dbus
        p.cairo
        p.pango
        p.expat
        p.libgbm
        p.libdrm
        p.libGL
        p.alsa-lib
        p.systemd # libudev, and the systemctl the service shells out to
        p.stdenv.cc.cc.lib
      ]
      ++ (with p.xorg; [
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libXi
        libXinerama
        libXtst
        libxkbfile
        libxcb
        libICE
        libSM
      ]);
    profile = ''
      export QT_PLUGIN_PATH=/usr/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
    '';
  };

  dir = "${unpacked}/lib/synergy3";

  desktopItem = pkgs.makeDesktopItem {
    name = "synergy3";
    desktopName = "Synergy 3";
    comment = "Use the keyboard, mouse, or trackpad of one computer to control nearby computers.";
    exec = "synergy3 %U";
    icon = "synergy";
    startupWMClass = "synergy";
    categories = [ "Utility" ];
  };
in
pkgs.symlinkJoin {
  name = "synergy3-${version}";
  paths = [
    # The Electron sandbox helper can't be setuid from the store; the app's
    # renderers still run, just without Chromium's sandbox.
    (pkgs.writeShellScriptBin "synergy3" ''
      exec ${fhs}/bin/synergy3-fhs ${dir}/synergy --no-sandbox "$@"
    '')
    (pkgs.writeShellScriptBin "synergy3-service" ''
      cd ${dir}
      exec ${fhs}/bin/synergy3-fhs ${dir}/synergy-service "$@"
    '')
    (pkgs.writeShellScriptBin "synergy3-core" ''
      exec ${fhs}/bin/synergy3-fhs ${dir}/synergy-core "$@"
    '')
    desktopItem
    "${unpacked}"
  ];
  passthru = { inherit unpacked fhs; };
  inherit (unpacked) meta;
}
