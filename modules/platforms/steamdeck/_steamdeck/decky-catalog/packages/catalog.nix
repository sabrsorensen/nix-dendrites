{ pkgs }:
let
  mkDeckyPlugin = pkgs.callPackage ./mk-plugin.nix { };
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
    }:
    mkDeckyPlugin {
      inherit pname verifyMainPy executablePaths;
      version = if rev == "main" || rev == "master" then "unstable" else rev;
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev;
        hash = srcHash;
      };
      hash = pnpmHash;
    };
in
{
  "decky-audio-loader" = mk {
    pname = "decky-audio-loader";
    owner = "DeckThemes";
    repo = "SDH-AudioLoader";
    rev = "main";
    srcHash = "sha256-9UQOMyeaofrbw7KSNn1kgdgeeDSjqLJFtYYO+EYKwGo=";
    pnpmHash = "sha256-eKMmkRemqx7jOnnGH5hdMt11c9bPiYlInu4ru9FLyfk=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-steamgriddb" = mk {
    pname = "decky-steamgriddb";
    owner = "SteamGridDB";
    repo = "decky-steamgriddb";
    rev = "HEAD";
    srcHash = "sha256-3+7k24L3nYW7zoKzTPC3khOubs00plbGoIuFmxT6jB8=";
    pnpmHash = "sha256-FRIkp2GuP/kVaxpq7Sn6DYsUbE2O/g8vxin+pl+3ZNw=";
  };
  "decky-lookup" = mk {
    pname = "decky-lookup";
    owner = "xXJSONDeruloXx";
    repo = "Decky-Lookup";
    rev = "main";
    srcHash = "sha256-Z2dvdxuo98q4FwatEJ/fs5Wwdq9zSrUt/g5vPgW/k44=";
    pnpmHash = "sha256-8fqu4t5oy2Y23cU1vhz9vnw8H2m7TCH+yLsz5GzXh/E=";
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
  };
  "decky-protondb" = mk {
    pname = "decky-protondb";
    owner = "bschelst";
    repo = "protondb-decky";
    rev = "main";
    srcHash = "sha256-gXJH16PQNSiOPzWldeqShq0UxT9KUeaygINsNPHWifs=";
    pnpmHash = "sha256-WJlCk355suOqpHyEse23uglk0XTB33D53CHmOyTS6v0=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-tabmaster" = mk {
    pname = "decky-tabmaster";
    owner = "Tormak9970";
    repo = "TabMaster";
    rev = "v2.16.2";
    srcHash = "sha256-I2czx1mh6KD/Uve7uhFOck4kHqhCoNMNl4SZC5VrQzY=";
    pnpmHash = "sha256-pA9OCFj4xdtAST7qwmYUI/ZdNhWN0PvYCvYi3H8/mcQ=";
    verifyMainPy = false;
  };
  "decky-autoflatpaks" = mk {
    pname = "decky-autoflatpaks";
    owner = "jurassicplayer";
    repo = "decky-autoflatpaks";
    rev = "main";
    srcHash = "sha256-CjVjHAjTGMP5ATo+7lDwOZ0OI0SvjkqVYUd0xHjfLbA=";
    pnpmHash = "sha256-xZChs8C6+CVAcU6vaPnOpQa3m91YiDp8doxTKAuZc98=";
  };
  "decky-bluetooth" = mk {
    pname = "decky-bluetooth";
    owner = "Outpox";
    repo = "Bluetooth";
    rev = "main";
    srcHash = "sha256-iRffRd13ABENTW4b1tFjaK40s2rvVbumeBPDsRIohjU=";
    pnpmHash = "sha256-02S4/SRPo9hSioDwyPgPNBdfEurX9yaXbq8MbqwK8pY=";
  };
  "decky-kdeconnect" = mk {
    pname = "decky-kdeconnect";
    owner = "safijari";
    repo = "Decky-KDE-Connect";
    rev = "main";
    srcHash = "sha256-hX2VOy1Q90umizQ3WXuSLRfR49ZOnIQ+/xCIaAZcWuI=";
    pnpmHash = "sha256-fqNiU22sjdOArkYQkWnQGR819HU+xpXFt5fPS9qrwic=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-web-browser" = mk {
    pname = "decky-web-browser";
    owner = "jessebofill";
    repo = "DeckWebBrowser";
    rev = "master";
    srcHash = "sha256-qilaHvk/HiOaqBl1IgBLtfVoPaYph0yuoS+p7yG9aCE=";
    pnpmHash = "sha256-c61m7jlyx4vTbalB7EVd0fc+TH/uFXeYRBxEIDEj2FE=";
    executablePaths = [ "*/bin/*" ];
  };
  "decky-museck" = mk {
    pname = "decky-museck";
    owner = "Nezreka";
    repo = "Museck";
    rev = "main";
    srcHash = "sha256-l1DXMRfTd9CfOBPe9DVjnLGcaQVQXBgfJ0hIzfBUjGU=";
    pnpmHash = "sha256-o7PQ7XMtaA3kypofskunp5/NaNcJFn+4CT1NIGm3MSI=";
    verifyMainPy = false;
  };
}
