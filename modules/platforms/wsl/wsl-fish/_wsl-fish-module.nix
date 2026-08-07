{ }:
{
  interactiveShellInit = ''
    if command -sq gpg
      set -gx GPG_TTY (tty)
    end
  '';
  functions = {
    editorSyncWindows = "editor-sync-windows $argv";
    esw = "editorSyncWindows $argv";
    editorSyncWindowsExtensions = "editor-sync-windows --install-extensions $argv";
    eswe = "editorSyncWindowsExtensions $argv";
    choco = "choco.exe $argv";
    wsl = "wsl.exe $argv";
  };
}
