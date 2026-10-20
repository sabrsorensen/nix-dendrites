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
  # 2.1.3 is untagged upstream (latest release is still v2.1.2).
  version = "2.1.3";
  src = fetchFromGitHub {
    owner = "DeckThemes";
    repo = "SDH-CssLoader";
    rev = "295150180e278fac6c3f45e2295f1ff1f28f92f8";
    hash = "sha256-Dhbob682RILKXfyK52dqPtkDfs69MB5wPNbV2l0uU2U=";
  };
  hash = "sha256-cdKYY2+1wJR7ME7Tj0FZnhP00nrsUetcxbjFZGbGZfg=";
  # Upstream's pnpm-lock.yaml is lockfileVersion 6.0, too old for pnpm_11 to
  # force-convert under --frozen-lockfile; read it with the pnpm major it was
  # generated for instead of forcing a fresh (potentially drifted) one.
  pnpm = import ./_pnpm9.nix { inherit pkgs; };
  fetcherVersion = 3;
  postPatch = ''
    cp ${./assets/vendor/css-loader-main.py} main.py
  '';
  inherit sourceReplacementScript;
  extraInstall = lib.optionalString (themeConfig != null) ''
    cp ${themeConfig} "$out/nix-css-themes.json"
  '';
  meta = with lib; {
    description = "CSS theme loader for Steam Deck";
    homepage = "https://github.com/DeckThemes/SDH-CssLoader";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
