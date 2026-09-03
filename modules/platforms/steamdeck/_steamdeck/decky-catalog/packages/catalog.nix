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
    }:
    mkDeckyPlugin (
      {
        inherit pname verifyMainPy executablePaths;
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
    srcHash = "sha256-E09yECuizhPKSnbn4FGvU4+1jNn4dq5oxJCuloqX30Q=";
    pnpmHash = "sha256-Hf2tFLlScnHh97EthKNXxkEbykU6xjC3s1iA7AqJ1r4=";
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
}
