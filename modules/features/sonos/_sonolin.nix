{
  lib,
  python3Packages,
  qt6,
  ffmpeg,
  pulseaudio,
  espeak-ng,
  openssl,
  sonolin-src,
}:
python3Packages.buildPythonApplication {
  pname = "sonolin";
  inherit ((lib.importTOML "${sonolin-src}/pyproject.toml").project) version;
  pyproject = true;

  src = sonolin-src;

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    soco
    aiohttp
    pyqt6
  ];

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];
  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
  ];

  # Desktop audio streaming shells out to ffmpeg and pactl; announcements to
  # espeak-ng. All are looked up by bare name.
  dontWrapQtApps = true;
  makeWrapperArgs = [
    "\${qtWrapperArgs[@]}"
    "--prefix PATH : ${
      lib.makeBinPath [
        ffmpeg
        pulseaudio
        espeak-ng
      ]
    }"
  ];

  # Upstream's `python -m sonolin.desktop install` writes a per-user entry;
  # install the packaged one instead.
  postInstall = ''
    install -Dm644 data/sonolin.desktop $out/share/applications/sonolin.desktop
    install -Dm644 data/icons/sonolin.svg $out/share/icons/hicolor/scalable/apps/sonolin.svg
  '';

  # tests/test_tags.py calls os.mkfifo without importing os (upstream bug at
  # 1429e886); see the warning in _sonos-home.nix. Fails loudly once upstream
  # adds the import so this gets dropped.
  postPatch = ''
    if grep -q '^import os$' tests/test_tags.py; then
      echo "sonolin: tests/test_tags.py now imports os; drop this postPatch" >&2
      exit 1
    fi
    sed -i '1i import os' tests/test_tags.py
  '';

  # tests/test_ws.py generates a throwaway TLS cert with the openssl CLI.
  nativeCheckInputs = [
    python3Packages.pytestCheckHook
    openssl
  ];
  preCheck = ''
    export QT_QPA_PLATFORM=offscreen
    export HOME=$TMPDIR
  '';

  pythonImportsCheck = [ "sonolin" ];

  meta = {
    description = "Sonos controller for the Linux desktop";
    homepage = "https://github.com/alexsson-xexpanderx/sonolin";
    license = lib.licenses.gpl3Only;
    mainProgram = "sonolin-gui";
    platforms = lib.platforms.linux;
  };
}
