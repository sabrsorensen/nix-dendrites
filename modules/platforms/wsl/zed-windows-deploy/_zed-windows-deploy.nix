{
  lib,
  pkgs,
  ...
}:
let
  # Reuse the Linux profile's data without enabling or installing the Linux UI.
  profile = (import ../../../home/zed/_zed.nix { inherit pkgs; }).programs.zed-editor;
  windowsSettings = profile.userSettings // {
    # The Windows client uses its own default shell. WSL remote projects can
    # still use fish, and the Linux-side tools below are available there.
    terminal = builtins.removeAttrs profile.userSettings.terminal [ "shell" ];
    auto_install_extensions = lib.genAttrs profile.extensions (_: true);
  };
  settingsFile = pkgs.writeText "zed-windows-settings.json" (builtins.toJSON windowsSettings);
  keymapFile = pkgs.writeText "zed-windows-keymap.json" (builtins.toJSON profile.userKeymaps);
  themeFile = pkgs.writeText "zed-windows-party-owl-84.json" (
    builtins.toJSON profile.themes.party-owl-84
  );
  python = pkgs.python3.withPackages (packages: [ packages.json5 ]);
  syncScript = pkgs.writeShellApplication {
    name = "zed-sync-windows";
    runtimeInputs = with pkgs; [
      coreutils
      python
    ];
    text = ''
      if [ "$#" -ne 0 ]; then
        echo "Usage: zed-sync-windows" >&2
        exit 1
      fi

      if ! command -v cmd.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
        echo "Windows interop is unavailable; skipping Zed profile sync." >&2
        exit 0
      fi

      if ! appdata_win="$(cmd.exe /d /c echo %APPDATA% | tr -d '\r')" || [ -z "$appdata_win" ]; then
        echo "Unable to resolve Windows APPDATA; skipping Zed profile sync." >&2
        exit 0
      fi
      if ! appdata_dir="$(wslpath -u "$appdata_win")" || [ ! -d "$appdata_dir" ]; then
        echo "Windows APPDATA is unavailable; skipping Zed profile sync." >&2
        exit 0
      fi

      python ${./_sync.py} \
        "$appdata_dir/Zed" \
        ${settingsFile} \
        ${keymapFile} \
        ${themeFile}
    '';
  };
in
{
  # Language servers and formatters run inside WSL for WSL projects.
  home.packages = profile.extraPackages ++ [ syncScript ];
  home.activation.syncZedToWindows = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe syncScript}
  '';
}
