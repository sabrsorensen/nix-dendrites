{
  flake.modules.homeManager."vscode-wsl" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      flavor = config.my.editor.packageFlavor;
      product = import ./_product.nix {
        inherit flavor;
      };
      # WSL is the declarative source of truth for editor config here.
      # Home Manager renders the Linux-side User tree, then the sync
      # script mirrors the managed files into the writable Windows profile.
      cfg = config.my.editor.windowsInterop;
      vscodeCfg = if flavor == "vscodium" then config.programs.vscodium else config.programs.vscode;
      extensionsHomePath =
        if flavor == "vscodium" then ".vscode-oss/extensions" else ".vscode/extensions";
      linuxUserDir = "${config.xdg.configHome}/${product.configDirName}/User";
      exportRoot = "${config.xdg.stateHome}/${product.stateDirName}-sync";
      exportUserDir = "${exportRoot}/${product.configDirName}/User";
      managedPaths = [
        "settings.json"
        "keybindings.json"
        "mcp.json"
        "snippets"
        "profiles"
      ];
      managedPathsFile = pkgs.writeText "vscode-managed-paths.txt" (
        lib.concatStringsSep "\n" managedPaths + "\n"
      );
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
      syncScript = pkgs.writeShellApplication {
        name = "editor-sync-windows";
        runtimeInputs = with pkgs; [
          coreutils
          findutils
          gnused
        ];
        text = ''
          set -eu

          install_extensions=0
          if [ "''${1:-}" = "--install-extensions" ]; then
            install_extensions=1
            shift
          fi

          if [ "$#" -ne 0 ]; then
            echo "Usage: editor-sync-windows [--install-extensions]" >&2
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

            wslpath -u "$appdata_win/${product.windowsConfigDirName}/User"
          }

          sync_managed_path() {
            src_root="$1"
            dst_root="$2"
            rel_path="$3"
            dst_path="''${dst_root:?}/''${rel_path:?}"

            rm -rf -- "$dst_path"
            if [ -e "$src_root/$rel_path" ]; then
              mkdir -p "$dst_root/$(dirname "$rel_path")"
              cp -RL "$src_root/$rel_path" "$dst_root/$rel_path"
            fi
          }

          sync_tree() {
            src_root="$1"
            dst_root="$2"

            mkdir -p "$dst_root"

            while IFS= read -r rel_path; do
              if [ -n "$rel_path" ]; then
                sync_managed_path "$src_root" "$dst_root" "$rel_path"
              fi
            done < ${managedPathsFile}
          }

          install_windows_extensions() {
            if ! command -v cmd.exe >/dev/null 2>&1 || ! command -v where.exe >/dev/null 2>&1; then
              echo "cmd.exe not found; skipping extension install." >&2
              return 0
            fi

            if ! where.exe ${lib.escapeShellArg product.windowsCli} >/dev/null 2>&1; then
              echo "${product.windowsCli} not found on the Windows PATH; skipping extension install." >&2
              return 0
            fi

            while IFS= read -r extension_id; do
              if [ -n "$extension_id" ]; then
                cmd.exe /d /c ${lib.escapeShellArg product.windowsCli} --install-extension "$extension_id" --force >/dev/null
              fi
            done < ${extensionIdsFile}
          }

          windows_user_dir="$(resolve_windows_user_dir || true)"
          if [ -z "$windows_user_dir" ]; then
            echo "Unable to resolve Windows ${product.windowsConfigDirName} User directory; skipping sync." >&2
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
      };
    in
    {
      options.my.editor.windowsInterop = {
        syncToWindows =
          lib.mkEnableOption "sync Home Manager editor files from WSL into the Windows editor profile"
          // {
            default = true;
          };

        targetUserDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Override for the Windows editor User directory as a WSL/Linux path. When null, it is derived from %APPDATA%.";
        };
      };

      config = {
        home.packages = [ syncScript ];
        # WSL keeps extensions installed in the Windows editor. Keep the
        # declarative extension list for sync/install metadata, but avoid
        # materializing a Linux-side immutable extensions tree.
        home.file.${extensionsHomePath}.source = lib.mkForce pkgs.emptyDirectory;

        home.activation.syncEditorToWindows = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          lib.optionalString (cfg.syncToWindows && vscodeCfg.enable) ''
            # Keep Windows editor config aligned with the HM-managed WSL export.
            run ${lib.getExe syncScript}
          ''
        );
        programs.vscode = lib.mkIf (flavor == "vscode") {
          package = lib.mkForce null;
        };
        programs.vscodium = lib.mkIf (flavor == "vscodium") {
          package = lib.mkForce null;
        };
      };
    };
}
