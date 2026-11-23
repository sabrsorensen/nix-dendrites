{
  lib,
  pkgs,
  fetchSymless,
}:
# Synergy 4 "Dragon" beta, unpacked untouched from Symless's Arch package.
#
# Its Go service, agent and launchers hard-code /usr/lib/synergy-dragon,
# /usr/libexec/synergy-dragon-launcher and /usr/bin/systemctl, and the service
# seeds and self-updates copies of the binaries under
# /var/lib/synergy-dragon/versions and runs them from there. None of that
# survives patchelf, so the unpacked tree is placed at its FHS paths inside a
# buildFHSEnv and every entry point (system service, session agent, GUI) runs
# through it; binaries it later downloads run in the same environment.
let
  version = "4.0.0";

  unpacked = pkgs.stdenvNoCC.mkDerivation {
    pname = "synergy4-unwrapped";
    inherit version;

    src = fetchSymless {
      product = "synergy-dragon";
      file = "synergy-dragon-${version}-linux-arch-x86_64.pkg.tar.zst";
      hash = "sha256-WQL8KZVrcNZoC2TbrNOVDKFvRTC4B4HPkizDPrQc8dg=";
    };

    nativeBuildInputs = [ pkgs.zstd ];

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    unpackPhase = ''
      runHook preUnpack
      mkdir src
      tar --zstd -xf "$src" -C src
      runHook postUnpack
    '';

    # Laid out as the FHS env's /usr. The package's own bin/ symlink points at
    # /usr/lib/... and only resolves inside the env, which is where it's used.
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp -a src/usr/lib/synergy-dragon "$out/lib/synergy-dragon"
      cp -a src/usr/libexec "$out/libexec"
      cp -a src/usr/bin "$out/bin"
      cp -a src/usr/share "$out/share"
      # Kept for reference; NixOS declares the units, preset and polkit rule.
      mkdir -p "$out/share/synergy-dragon/packaging"
      cp -a src/etc src/usr/lib/systemd "$out/share/synergy-dragon/packaging/"
      runHook postInstall
    '';

    meta = {
      description = "Synergy 4 Dragon Beta (unwrapped Symless package)";
      homepage = "https://symless.com/synergy";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };

  fhs = pkgs.buildFHSEnv {
    pname = "synergy4-fhs";
    inherit version;
    runScript = pkgs.writeShellScript "synergy4-exec" ''exec "$@"'';
    targetPkgs =
      p:
      [
        unpacked
        # synergy-core: Qt 6.12, libei, OpenSSL 4
        p.qt6.qtbase
        p.qt6.qtwayland
        p.libei
        p.openssl_4_1
        p.libxkbcommon
        p.libglvnd
        p.glib
        # synergy-dragon-gui: WebKitGTK 4.1 / libsoup 3
        p.webkitgtk_4_1
        p.libsoup_3
        p.gtk3
        p.gdk-pixbuf
        p.pango
        p.cairo
        p.harfbuzz
        p.atk
        p.zlib
        p.systemd # /usr/bin/systemctl
        p.stdenv.cc.cc.lib
      ]
      ++ (with p.xorg; [
        libX11
        libXext
        libXi
        libXinerama
        libXrandr
        libXtst
        libxkbfile
        libICE
        libSM
      ]);
    profile = ''
      export QT_PLUGIN_PATH=/usr/lib/qt-6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
    '';
  };

  run = "${fhs}/bin/synergy4-fhs";

  desktopItem = pkgs.makeDesktopItem {
    name = "synergy-dragon";
    desktopName = "Synergy 4 Dragon Beta";
    genericName = "Keyboard and Mouse Sharing";
    comment = "Share one keyboard and mouse between computers";
    exec = "synergy-dragon-gui";
    icon = "synergy-dragon";
    startupWMClass = "synergy-dragon-gui";
    categories = [
      "Network"
      "RemoteAccess"
    ];
  };
in
pkgs.symlinkJoin {
  name = "synergy4-${version}";
  paths = [
    (pkgs.writeShellScriptBin "synergy-dragon-gui" ''
      exec ${run} /usr/lib/synergy-dragon/synergy-dragon-gui-launcher "$@"
    '')
    (pkgs.writeShellScriptBin "synergy-dragon-agent" ''
      exec ${run} /usr/lib/synergy-dragon/synergy-dragon-agent "$@"
    '')
    (pkgs.writeShellScriptBin "synergy-dragon-service" ''
      exec ${run} /usr/lib/synergy-dragon/synergy-dragon-service "$@"
    '')
    (pkgs.writeShellScriptBin "synergy-dragon-launcher" ''
      exec ${run} /usr/libexec/synergy-dragon-launcher "$@"
    '')
    desktopItem
    (pkgs.runCommand "synergy4-icons" { } ''
      mkdir -p "$out/share"
      cp -a ${unpacked}/share/icons "$out/share/icons"
    '')
  ];
  passthru = { inherit unpacked fhs; };
  inherit (unpacked) meta;
}
