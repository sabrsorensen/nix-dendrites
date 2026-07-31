{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  username = config.my.host.home.username;
  vscodePackage =
    inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-partyowl84;
  extensions = import ../_extensions-content.nix {
    baseThemePackage = vscodePackage;
    cfg.packageFlavor = "vscode";
    inherit pkgs;
  };
  settings = import ../_settings-content.nix { vscodeTheme = "partyowl84"; };
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
  # The Windows editor owns its extension directory. Keep the WSL
  # default/Higi inventory as data for on-demand installation without an
  # immutable Linux extension tree.
  extensionIds = lib.unique (
    extensions.defaultExtensionIds
    ++ extensions.pythonExtensionIds
    ++ extensions.higiExtensionIds
    ++ extensions.fishExtensionIds
    ++ extensions.nixExtensionIds
  );
  extensionIdsFile = pkgs.writeText "vscode-extension-ids.txt" (
    lib.concatStringsSep "\n" extensionIds + "\n"
  );
  windowsTerminalSettings = {
    "terminal.integrated.defaultProfile.windows" = "NixOS (WSL)";
    "terminal.integrated.profiles.windows" = {
      "PowerShell" = {
        source = "PowerShell";
        icon = "terminal-powershell";
      };
      "Command Prompt" = {
        path = [
          "\${env =windir}\\Sysnative\\cmd.exe"
          "\${env =windir}\\System32\\cmd.exe"
        ];
        args = [ ];
        icon = "terminal-cmd";
      };
      "NixOS (WSL)" = {
        path = "C =\\windows\\System32\\wsl.exe";
        args = [
          "-d"
          "NixOS"
        ];
      };
    };
  };
  defaultProfileSettings = settings.defaultProfileUserSettings // windowsTerminalSettings;
  higiSettings = settings.mkHigiUserSettings { runCodexInWsl = true; };
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

      if ! command -v cmd.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
        echo "Windows interop is unavailable; skipping VS Code profile sync." >&2
        exit 0
      fi

      appdata_win="$(cmd.exe /d /c echo %APPDATA% | tr -d '\r')"
      if [ -z "$appdata_win" ]; then
        echo "Unable to resolve %APPDATA%; skipping VS Code profile sync." >&2
        exit 0
      fi

      source_root="$HOME/.config/Code/User"
      export_root="$HOME/.local/state/vscode-sync/Code/User"
      target_root="$(wslpath -u "$appdata_win/Code/User")"
      if [ -z "$target_root" ]; then
        echo "Unable to resolve the Windows Code User directory; skipping VS Code profile sync." >&2
        exit 0
      fi

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

      mkdir -p "$export_root"
      cp ${extensionIdsFile} "$HOME/.local/state/vscode-sync/extensions.txt"
      sync_tree "$source_root" "$export_root"
      sync_tree "$export_root" "$target_root"

      if [ "$install_extensions" -eq 1 ]; then
        if ! command -v where.exe >/dev/null 2>&1 || ! where.exe code >/dev/null 2>&1; then
          echo "Windows Code CLI is unavailable; skipping extension installation." >&2
          exit 0
        fi
        while IFS= read -r extension_id; do
          [ -n "$extension_id" ] || continue
          cmd.exe /d /c code --install-extension "$extension_id" --force >/dev/null
        done < ${extensionIdsFile}
      fi
    '';
  };
in
{
  nixpkgs.overlays = [ inputs.nix4vscode.overlays.forVscode ];
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
      # Declare profiles without installing a Linux Code executable;
      # Windows remains the executable owner.
      package = lib.mkForce null;
      profiles = {
        default.enableMcpIntegration = true;
        Higi_LLP = {
          extensions = extensions.mkExtensions (
            extensions.defaultExtensionIds ++ extensions.pythonExtensionIds ++ extensions.higiExtensionIds
          );
          enableMcpIntegration = true;
        };
        Nix = {
          extensions = extensions.mkExtensions (
            extensions.defaultExtensionIds
            ++ extensions.pythonExtensionIds
            ++ extensions.fishExtensionIds
            ++ extensions.nixExtensionIds
          );
          enableMcpIntegration = true;
        };
        # Retain empty profile metadata even though WSL does not enable
        # these profiles' extension sets.
        Python = { };
        STM32 = { };
      };
    };
    home = {
      packages = [ syncScript ];
      # Keep Linux's extension tree empty. Windows Code owns the real
      # extension directory and receives the inventory on demand.
      file.".vscode/extensions".source = lib.mkForce pkgs.emptyDirectory;
      file.".config/Code/User/settings.json".text = builtins.toJSON defaultProfileSettings;
      file.".config/Code/User/keybindings.json".text = builtins.toJSON settings.defaultKeybindings;
      file.".config/Code/User/profiles/Higi_LLP/settings.json".text = builtins.toJSON higiSettings;
      file.".config/Code/User/profiles/Higi_LLP/keybindings.json".text =
        builtins.toJSON settings.defaultKeybindings;
      file.".config/Code/User/profiles/Nix/settings.json".text =
        builtins.toJSON settings.nixProfileUserSettings;
      file.".config/Code/User/profiles/Nix/keybindings.json".text =
        builtins.toJSON settings.defaultKeybindings;
      file.".config/Code/User/profiles/Nix/snippets/nix.json".text =
        builtins.toJSON settings.nixProfileSnippets.nix;
      file.".config/Code/User/profiles/Nix/snippets/json.json".text =
        builtins.toJSON settings.nixProfileSnippets.json;
    };
    home.activation.syncEditorToWindows =
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
        ''
          run ${lib.getExe syncScript}
        '';
  };
}
