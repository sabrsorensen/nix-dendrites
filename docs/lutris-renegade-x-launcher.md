# Installing Renegade X via Lutris (community/manual installer)

Renegade X has no official Lutris installer script that works reliably; the
community "Total Chaos"-style script that shows up on lutris.net fails with
`Command exited with code 256`. This documents the manual installer script
and the Wine/Proton fix that were needed to get the Totem Arts Launcher
(which Renegade X installs and updates through) actually running, since none
of this is state the Nix config manages (per
`modules/features/lutris/lutris.nix`: game prefixes live in `~/Games` and are
out of scope for this repo). The one piece that *is* now in the repo is the
reusable Wine `powershell.exe` stub fix -- see the end of this doc.

## 1. Manual installer script

Lutris's `-i` flag can run a local YAML installer script instead of one from
lutris.net. Save this as e.g. `~/renegade-x-manual.yml` and run
`lutris -i ~/renegade-x-manual.yml`:

```yaml
name: Renegade X
game_slug: renegade-x
runner: wine
slug: renegade-x-manual-local
version: manual

script:
  files:
    - renx: 'N/A: Please select the .exe file from Totem Arts'
  game:
    arch: win64
    exe: drive_c/Program Files (x86)/Renegade X/Binaries/Win64/UDK.exe
    prefix: $GAMEDIR
  installer:
    - task:
        arch: win64
        description: Creating Wine prefix
        name: create_prefix
        prefix: $GAMEDIR
    - task:
        app: dotnet452
        description: Installing .net 4.5.2
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: corefonts
        description: Installing corefonts
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: vcrun2008
        description: Installing visual code 2008
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: vcrun2010
        description: Installing visual code 2010
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: xact
        description: Installing xact
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: xact_x64
        description: Installing xact_64
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: d3dx9
        description: Installing d3dx9
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: d3dx9_43
        description: Installing d3dx9_43.dll
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: msxml3
        description: Installing msxml3
        name: winetricks
        prefix: $GAMEDIR
    - task:
        app: win7
        description: Setting environment to Windows7
        name: winetricks
        prefix: $GAMEDIR
    - task:
        executable: $renx
        name: wineexec
        prefix: $GAMEDIR
```

When prompted, point `renx` at the Totem Arts Launcher installer exe
(`Totem-Arts-Launcher-latest.exe`, from the official Renegade X site) -- that
launcher is what actually downloads and installs the game and drives future
updates; it isn't the game's own installer.

Notes on shape, since these are easy to get wrong and each produces a
different failure:

- The whole `files`/`game`/`installer` body must be nested under a top-level
  `script:` key, or `lutris -i` fails with `KeyError: 'script'`.
- `wineexec`'s target field is `executable:`, not `args:` -- `args:` runs
  nothing and the install silently "succeeds" without launching anything.
- `name`, `game_slug`, `runner`, `slug`, `version` at the top level are all
  required; without them `lutris -i` crashes before it gets far enough to
  produce a useful error.

## 2. The launcher hangs on "detecting another instance, unable to close"

Once the script above runs clean, the Totem Arts Launcher itself may open
and immediately refuse to proceed, reporting it detected another running
instance it can't close -- reproducible even in a brand-new prefix that has
never run the launcher before (ruling out leftover lock files, registry
keys, or stray `wineserver` processes; all were checked and were clean).

Root cause, found via `WINEDEBUG=+powershell` (or just running the launcher
from a terminal and reading its stderr): the launcher's self-update logic
shells out to real Windows PowerShell + WMI
(`Get-CimInstance -ClassName Win32_Process`) to detect and kill other copies
of itself. Wine's (and GE-Proton's, which ships the same Wine source)
built-in `powershell.exe` is an **unimplemented stub** -- it logs
`fixme:powershell:wmain stub` and returns a fixed exit code no matter what
it's asked, which happens to land on the launcher's "another instance is
running" branch every time, regardless of reality. This is a genuine Wine
compatibility gap, not anything specific to this prefix.

### Fix

Replace `powershell.exe` with a tiny native program that inspects its own
arguments and returns the exit code that satisfies this launcher's specific
`-Command` patterns (`Get-CimInstance` / `Get-Command`) instead of Wine's
stub. This is now packaged in the repo -- see
`modules/features/lutris/_powershell-stub.nix`, exposed on any host with
`my.host.features.lutris` as the `wine-powershell-stub-install` command:

```bash
wine-powershell-stub-install ~/Games/renegade-x/pfx
```

Then make sure Wine actually resolves the on-disk file instead of its
builtin fake module: set `WINEDLLOVERRIDES="powershell=n"` for any process
run against that prefix. In Lutris: **Configure -> System options -> DLL
overrides -> powershell=n**, for the specific game entry.

Two things that look sufficient but are not, if you're re-deriving this by
hand:

- Copying only a 64-bit replacement to
  `system32\WindowsPowerShell\v1.0\powershell.exe` has no effect. The
  launcher is a 32-bit process, and Wine's WOW64 filesystem redirection
  transparently maps its `system32\` references to `syswow64\` -- so a
  32-bit build must also be placed at
  `syswow64\WindowsPowerShell\v1.0\powershell.exe`. This is why the packaged
  fix builds and installs both.
- On GE-Proton prefixes, both of those paths are symlinks into the shared
  GE-Proton install directory (e.g.
  `~/.local/share/Steam/compatibilitytools.d/GE-Proton*/files/lib/wine/...`).
  Overwriting through the symlink would patch every Proton game sharing that
  GE-Proton version; the fix removes the symlink and writes a real file at
  that path instead, which is what `wine-powershell-stub-install` does.

## 3. Remaining known issue

The launcher may complain about not running on "at least Windows XP SP 3"
when it tries to (re)install the Unreal Engine redistributable. This hasn't
blocked installing or launching the game -- noted here in case it resurfaces
as an actual problem later.
