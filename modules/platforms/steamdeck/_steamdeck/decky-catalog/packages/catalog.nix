{ pkgs }:
let
  mkDeckyPlugin = pkgs.callPackage ./mk-plugin.nix { };
  # Some upstream plugins still ship a pre-v9 pnpm-lock.yaml that pnpm_11
  # refuses to force-convert under --frozen-lockfile. Rather than force a
  # fresh lockfile (which re-resolves every unpinned transitive dependency
  # against whatever is newest today, drifting from what upstream actually
  # tested), read their real, committed lockfile with the pnpm major it was
  # generated for.
  pnpm9 = import ./_pnpm9.nix { inherit pkgs; };
  # Shared backend helpers for moi952's Decky plugins (decky-quick-tab). Not on
  # PyPI: upstream's package.sh vendors it into py_modules/ with
  #   pip3 install --target py_modules --no-deps git+…/decky-plugin-toolkit@v0.1.0
  # Packaged here so it can go through mkDeckyPlugin's `pythonDeps` like any
  # other backend dependency. Pure Python, no deps; pinned to the tag upstream
  # pins. `import decky` at module load is provided by Decky Loader at runtime,
  # so there is nothing to import-check at build time.
  deckyPluginToolkit = pkgs.python3Packages.buildPythonPackage {
    pname = "decky-plugin-toolkit";
    version = "0.1.0";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "moi952";
      repo = "decky-plugin-toolkit";
      rev = "v0.1.0";
      hash = "sha256-E9+X/htvr3eKAc80KH3y6++byjEY5VRYI55EtrSb9oo=";
    };
    build-system = [ pkgs.python3Packages.setuptools ];
    doCheck = false;
  };
  mk =
    {
      pname,
      owner,
      repo,
      rev,
      srcHash,
      pnpmHash,
      verifyMainPy ? true,
      executablePaths ? [ ],
      legacyLockfile ? false,
      pythonDeps ? [ ],
    }:
    mkDeckyPlugin (
      {
        inherit
          pname
          verifyMainPy
          executablePaths
          pythonDeps
          ;
        version = if rev == "main" || rev == "master" then "unstable" else rev;
        src = pkgs.fetchFromGitHub {
          inherit owner repo rev;
          hash = srcHash;
        };
        hash = pnpmHash;
      }
      // pkgs.lib.optionalAttrs legacyLockfile {
        pnpm = pnpm9;
        fetcherVersion = 3;
      }
    );
in
{
  "decky-audio-loader" = mk {
    pname = "decky-audio-loader";
    owner = "DeckThemes";
    repo = "SDH-AudioLoader";
    rev = "main";
    srcHash = "sha256-9UQOMyeaofrbw7KSNn1kgdgeeDSjqLJFtYYO+EYKwGo=";
    pnpmHash = "sha256-iZsmVp1vr+LVQRYlADMZDZFNgYenD58UGe2p+n3xzbM=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-steamgriddb" = mk {
    pname = "decky-steamgriddb";
    owner = "SteamGridDB";
    repo = "decky-steamgriddb";
    rev = "HEAD";
    srcHash = "sha256-3+7k24L3nYW7zoKzTPC3khOubs00plbGoIuFmxT6jB8=";
    pnpmHash = "sha256-FRIkp2GuP/kVaxpq7Sn6DYsUbE2O/g8vxin+pl+3ZNw=";
    legacyLockfile = true;
  };
  "decky-lookup" = mk {
    pname = "decky-lookup";
    owner = "xXJSONDeruloXx";
    repo = "Decky-Lookup";
    rev = "main";
    srcHash = "sha256-Z2dvdxuo98q4FwatEJ/fs5Wwdq9zSrUt/g5vPgW/k44=";
    pnpmHash = "sha256-ztV/7yhou+aAiU8BnWbvGTpDOdwmqqJCF+KTmPth/Xw=";
    verifyMainPy = false;
    executablePaths = [ "*/bin/*" ];
  };
  "decky-isthereanydeal" = mk {
    pname = "decky-isthereanydeal";
    owner = "JtdeGraaf";
    repo = "IsThereAnyDeal-DeckyPlugin";
    rev = "main";
    srcHash = "sha256-QpY3tEuTde/NVLRX0OWLLqIHnGxUDTJTfNIot1dKLLk=";
    pnpmHash = "sha256-lmhw7aYSmkblSStHu0Z/ykU+YPsi+2e/3jSeUU4VNgI=";
    executablePaths = [ "*/bin/*" ];
    legacyLockfile = true;
  };
  "decky-protondb" = mk {
    pname = "decky-protondb";
    owner = "bschelst";
    repo = "protondb-decky";
    rev = "main";
    srcHash = "sha256-gXJH16PQNSiOPzWldeqShq0UxT9KUeaygINsNPHWifs=";
    pnpmHash = "sha256-I5RNOInDZE0hFZ48kf9iLtGe8cTKWrFRMGVufF5P3xI=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-tabmaster" = mk {
    pname = "decky-tabmaster";
    owner = "Tormak9970";
    repo = "TabMaster";
    rev = "v2.15.1";
    srcHash = "sha256-2BdTeVXeioxMRjjM9W/Vm/IYGVCWFsH2MOwDWIack4E=";
    pnpmHash = "sha256-3ZBIhYfEAfMVRJd6AL2viL/UrBUbzMKH4/++P7Jk6Z8=";
    verifyMainPy = false;
  };
  "decky-autoflatpaks" = mk {
    pname = "decky-autoflatpaks";
    owner = "jurassicplayer";
    repo = "decky-autoflatpaks";
    rev = "main";
    srcHash = "sha256-CjVjHAjTGMP5ATo+7lDwOZ0OI0SvjkqVYUd0xHjfLbA=";
    pnpmHash = "sha256-NQUkUs+C4IeshpByseirr0ZIW00Dux8Jj/24amiZOd8=";
  };
  "decky-bluetooth" = mk {
    pname = "decky-bluetooth";
    owner = "Outpox";
    repo = "Bluetooth";
    rev = "main";
    srcHash = "sha256-kpwAHrFf35OlYR4S7zcyvQJgIuXoYZiLv8yfYPAsLQA=";
    pnpmHash = "sha256-Hf2tFLlScnHh97EthKNXxkEbykU6xjC3s1iA7AqJ1r4=";
    # requirements.txt: `jeepney==0.9.0`; main.py imports it. nixpkgs ships
    # jeepney 0.9 (zero deps).
    pythonDeps = [ pkgs.python3Packages.jeepney ];
  };
  "decky-kdeconnect" = mk {
    pname = "decky-kdeconnect";
    owner = "safijari";
    repo = "Decky-KDE-Connect";
    rev = "main";
    srcHash = "sha256-hX2VOy1Q90umizQ3WXuSLRfR49ZOnIQ+/xCIaAZcWuI=";
    pnpmHash = "sha256-fqNiU22sjdOArkYQkWnQGR819HU+xpXFt5fPS9qrwic=";
    executablePaths = [ "*/bin/*" ];
    legacyLockfile = true;
  };
  "decky-web-browser" = mk {
    pname = "decky-web-browser";
    owner = "jessebofill";
    repo = "DeckWebBrowser";
    rev = "master";
    srcHash = "sha256-qilaHvk/HiOaqBl1IgBLtfVoPaYph0yuoS+p7yG9aCE=";
    pnpmHash = "sha256-53TRL8rka+0I6LnVlpEw5AHhbcS2G2YJycVY1hpx7ms=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-museck" = mk {
    pname = "decky-museck";
    owner = "Nezreka";
    repo = "Museck";
    rev = "main";
    srcHash = "sha256-jCZoGmLcwS1CuY99lsYJ98l9+EvpGh8Kj2hDW5157yM=";
    pnpmHash = "sha256-1TKYD24kVNwgOWQzVKebHnGh4QHSXRTnKxZpRjGFIEo=";
    verifyMainPy = false;
  };
  "decky-quick-tab" = mk {
    pname = "decky-quick-tab";
    owner = "moi952";
    repo = "decky-quick-tab";
    rev = "main";
    srcHash = "sha256-ztalV1+O8a/LWntWQHXiWb5B0xQnJtaU9JGWKadNE3M=";
    pnpmHash = "sha256-PSrmejddekXI2MoFZiLb/WSWdDdUW0v1isiFFn8YJ2k=";
    # main.py -> quick_tab.plugin imports decky_plugin_toolkit; its __init__
    # swallows the resulting ImportError, so without the toolkit the backend
    # never exposes `Plugin` and get/set_tab_settings, restart_steam and the
    # update check all silently fail. Vendored via package.sh upstream.
    pythonDeps = [ deckyPluginToolkit ];
  };
}
