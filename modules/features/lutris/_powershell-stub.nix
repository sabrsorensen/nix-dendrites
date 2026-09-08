{
  lib,
  pkgsCross,
  writeShellApplication,
}:
let
  # Wine's bundled `powershell.exe` (and GE-Proton's, which ships the same
  # Wine source) is an unimplemented stub: whatever a caller's -Command
  # script asks, it prints `fixme:powershell:wmain stub` and returns a fixed
  # exit code, doing nothing else. Some Windows apps use real PowerShell +
  # WMI (Get-CimInstance/Get-Command) as a singleton-instance check at
  # startup; against the stub, that check always evaluates as "still
  # running" and the app refuses to proceed. Confirmed cause of the Totem
  # Arts Launcher (Renegade X) hanging on "detecting another instance,
  # unable to close" -- reproduced even in a brand-new prefix that had never
  # run the launcher before, ruling out leftover state. See
  # docs/lutris-renegade-x-launcher.md.
  #
  # Fix: replace powershell.exe with a tiny native program that inspects its
  # own argv for the specific patterns this class of self-update logic
  # greps for, and returns the exit code that satisfies "no other instance
  # running". Needs building for *both* prefix architectures: Wine's WOW64
  # filesystem redirection means a 32-bit caller's references to system32\
  # transparently resolve to syswow64\, so a 32-bit process (this launcher)
  # never even reaches a system32-only replacement -- confirmed by
  # reproduction (the 64-bit-only fix silently had no effect; adding the
  # 32-bit build at the syswow64 path is what actually worked).
  stubSrc = builtins.toFile "wine-powershell-stub.c" ''
    #include <string.h>
    int main(int argc, char **argv) {
        for (int i = 1; i < argc; i++) {
            if (strstr(argv[i], "Get-CimInstance") || strstr(argv[i], "Get-Command"))
                return 1;
        }
        return 0;
    }
  '';

  mkStub =
    crossPkgs: exeName:
    crossPkgs.stdenv.mkDerivation {
      pname = "wine-powershell-stub-${exeName}";
      version = "1";
      dontUnpack = true;
      buildPhase = ''
        runHook preBuild
        $CC -O2 -o ${exeName} ${stubSrc}
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        install -Dm755 ${exeName} $out/bin/${exeName}
        runHook postInstall
      '';
    };

  stub64 = mkStub pkgsCross.mingwW64 "powershell64.exe";
  stub32 = mkStub pkgsCross.mingw32 "powershell32.exe";
in
writeShellApplication {
  name = "wine-powershell-stub-install";
  text = ''
    prefix="''${1:?Usage: wine-powershell-stub-install <wine-prefix-dir>}"
    sys64_dir="$prefix/drive_c/windows/system32/WindowsPowerShell/v1.0"
    sys32_dir="$prefix/drive_c/windows/syswow64/WindowsPowerShell/v1.0"
    mkdir -p "$sys64_dir" "$sys32_dir"

    # GE-Proton prefixes ship these paths as symlinks into the shared
    # GE-Proton install; remove the symlink rather than writing through it
    # so the shared install (used by every other Proton game) is untouched.
    rm -f "''${sys64_dir:?}/powershell.exe" "''${sys32_dir:?}/powershell.exe"
    install -Dm755 "${stub64}/bin/powershell64.exe" "$sys64_dir/powershell.exe"
    install -Dm755 "${stub32}/bin/powershell32.exe" "$sys32_dir/powershell.exe"

    cat <<'MSG'
    Installed powershell.exe stub (system32 64-bit + syswow64 32-bit) into
    the given Wine prefix.

    Also make sure Wine resolves this on-disk file instead of its builtin
    fake module, by setting WINEDLLOVERRIDES="powershell=n" for any process
    run against this prefix -- e.g. in Lutris: Configure -> System options
    -> DLL overrides -> add "powershell=n".
    MSG
  '';
}
