{
  flake.modules.homeManager."vscode-wsl" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # WSL is the declarative source of truth for VS Code config here.
      # Home Manager renders the Linux-side Code/User tree, then the sync
      # script mirrors the managed files into the writable Windows profile.
      cfg = config.my.vscode.windowsInterop;
      vscodeCfg = config.programs.vscode;
      linuxUserDir = "${config.xdg.configHome}/Code/User";
      exportRoot = "${config.xdg.stateHome}/vscode-sync";
      exportUserDir = "${exportRoot}/Code/User";
      managedPaths = [
        "settings.json"
        "keybindings.json"
        "mcp.json"
        "snippets"
        "profiles"
      ];
      targetUserDirOverride = cfg.targetUserDir or "";
      allExtensions = lib.flatten (
        lib.mapAttrsToList (_name: profile: profile.extensions) vscodeCfg.profiles
      );
      extensionIds = lib.unique (
        lib.flatten (
          map (
            ext:
            if ext ? vscodeExtUniqueId then
              [ ext.vscodeExtUniqueId ]
            else
              builtins.attrNames (builtins.readDir "${ext}/share/vscode/extensions")
          ) allExtensions
        )
      );
      extensionIdsFile = pkgs.writeText "vscode-extension-ids.txt" (
        lib.concatStringsSep "\n" extensionIds + "\n"
      );
      syncScript = pkgs.writeShellScriptBin "vscode-sync-windows" ''
        set -eu

        install_extensions=0
        if [ "''${1:-}" = "--install-extensions" ]; then
          install_extensions=1
          shift
        fi

        if [ "$#" -ne 0 ]; then
          echo "Usage: vscode-sync-windows [--install-extensions]" >&2
          exit 1
        fi

        resolve_windows_user_dir() {
          if [ -n ${lib.escapeShellArg targetUserDirOverride} ]; then
            printf '%s\n' ${lib.escapeShellArg targetUserDirOverride}
            return 0
          fi

          if ! command -v cmd.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
            return 1
          fi

          appdata_win="$(cmd.exe /d /c echo %APPDATA% | tr -d '\r')"
          if [ -z "$appdata_win" ]; then
            return 1
          fi

          wslpath -u "$appdata_win/Code/User"
        }

        sync_tree() {
          src="$1"
          dst="$2"

          mkdir -p "$dst"

          for path in ${lib.escapeShellArgs managedPaths}; do
            rm -rf "$dst/$path"
            if [ -e "$src/$path" ]; then
              cp -RL "$src/$path" "$dst/$path"
            fi
          done
        }

        install_windows_extensions() {
          if ! command -v cmd.exe >/dev/null 2>&1 || ! command -v where.exe >/dev/null 2>&1; then
            echo "cmd.exe not found; skipping extension install." >&2
            return 0
          fi

          if ! where.exe code.cmd >/dev/null 2>&1; then
            echo "code.cmd not found on the Windows PATH; skipping extension install." >&2
            return 0
          fi

          while IFS= read -r extension_id; do
            if [ -n "$extension_id" ]; then
              cmd.exe /d /c code.cmd --install-extension "$extension_id" --force >/dev/null
            fi
          done < ${extensionIdsFile}
        }

        windows_user_dir="$(resolve_windows_user_dir || true)"
        if [ -z "$windows_user_dir" ]; then
          echo "Unable to resolve Windows VS Code User directory; skipping sync." >&2
          exit 0
        fi

        mkdir -p ${lib.escapeShellArg exportRoot}
        cp ${lib.escapeShellArg extensionIdsFile} ${lib.escapeShellArg "${exportRoot}/extensions.txt"}
        sync_tree ${lib.escapeShellArg linuxUserDir} ${lib.escapeShellArg exportUserDir}
        sync_tree ${lib.escapeShellArg exportUserDir} "$windows_user_dir"

        if [ "$install_extensions" -eq 1 ]; then
          install_windows_extensions
        fi
      '';
    in
    {
      options.my.vscode.windowsInterop = {
        syncToWindows =
          lib.mkEnableOption "sync Home Manager VS Code files from WSL into the Windows VS Code profile"
          // {
            default = true;
          };

        targetUserDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Override for the Windows VS Code User directory as a WSL/Linux path. When null, it is derived from %APPDATA%.";
        };
      };

      config = {
        programs.vscode = {
          package = lib.mkForce null;
        };

        home.packages = [ syncScript ];

        home.activation.syncVscodeToWindows = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          lib.optionalString (cfg.syncToWindows && vscodeCfg.enable) ''
            # Keep Windows VS Code config aligned with the HM-managed WSL export.
            run ${lib.getExe syncScript}
          ''
        );
      };
    };
}
