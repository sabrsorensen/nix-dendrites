{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  pkgs,
  themeConfig ? null,
}:
let
  writeSourceReplacementScript = import ./_write-source-replacement-script.nix { inherit pkgs; };
  sourceReplacementScript = writeSourceReplacementScript {
    scriptName = "decky-css-loader-nixos-fix";
    defaultFile = "css_utils.py";
    replacements = [
      {
        kind = "literal";
        reason = "Ensure shutil is imported for copy-based theme installation.";
        old = "import os";
        new = "import os\nimport shutil";
        expectedCount = 1;
      }
      {
        kind = "literal";
        reason = "Use copy-based theme installation instead of symlinks.";
        old = "os.symlink(";
        new = "shutil.copy2(";
        minCount = 0;
        maxCount = 1;
      }
      {
        kind = "literal";
        reason = "Use copy-based theme installation instead of hard links.";
        old = "os.link(";
        new = "shutil.copy2(";
        minCount = 0;
        maxCount = 1;
      }
    ];
  };
in
mkDeckyPlugin {
  pname = "decky-css-loader";
  version = "2.1.2";
  src = fetchFromGitHub {
    owner = "suchmememanyskill";
    repo = "SDH-CssLoader";
    rev = "v2.1.2";
    hash = "sha256-dEhK1LcOMerSQsOiUahMm/RX78ABNsKReQfRfspyw68=";
  };
  hash = "sha256-cdKYY2+1wJR7ME7Tj0FZnhP00nrsUetcxbjFZGbGZfg=";
  postPatch = ''
    cp ${./assets/vendor/css-loader-main.py} main.py
  '';
  inherit sourceReplacementScript;
  extraInstall = lib.optionalString (themeConfig != null) ''
    cp ${themeConfig} "$out/nix-css-themes.json"
  '';
  meta = with lib; {
    description = "CSS theme loader for Steam Deck";
    homepage = "https://github.com/suchmememanyskill/SDH-CssLoader";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
