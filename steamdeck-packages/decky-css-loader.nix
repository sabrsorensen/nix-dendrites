{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  pkgs,
  themeConfig ? null,
  callPackage ? null,
}:

let
  cssThemeConfigBuilder =
    if callPackage != null then callPackage ./css-theme-config-simple.nix { } else null;

  patchScript = import ../lib/write-source-replacement-script.nix { inherit pkgs; } {
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

  mkCssLoader =
    {
      themeConfig ? null,
    }:
    mkDeckyPlugin {
      pname = "decky-css-loader";
      version = "2.1.2";

      src = fetchFromGitHub {
        owner = "suchmememanyskill";
        repo = "SDH-CssLoader";
        rev = "v2.1.2";
        sha256 = "sha256-dEhK1LcOMerSQsOiUahMm/RX78ABNsKReQfRfspyw68=";
      };

      hash = "sha256-cdKYY2+1wJR7ME7Tj0FZnhP00nrsUetcxbjFZGbGZfg=";
      postPatch = ''
        cp ${./patches/decky-css-loader-main.py} main.py
      '';
      sourceReplacementScript = patchScript;
      extraInstall = lib.optionalString (themeConfig != null) ''
        cp ${themeConfig} $out/nix-css-themes.json
      '';
      useFastPermissions = true;
      meta = with lib; {
        description = "CSS theme loader for Steam Deck";
        homepage = "https://github.com/suchmememanyskill/SDH-CssLoader";
        license = licenses.gpl3;
        platforms = platforms.linux;
      };
    };

  basePackage = mkCssLoader { };
in
basePackage.overrideAttrs (prev: {
  passthru = (prev.passthru or { }) // {
    inherit cssThemeConfigBuilder;

    withThemeConfig =
      themeConfig:
      mkCssLoader {
        inherit themeConfig;
      };

    withThemes =
      args:
      if cssThemeConfigBuilder != null then
        mkCssLoader {
          themeConfig = cssThemeConfigBuilder.buildNixCssThemeConfig args;
        }
      else
        throw "CSS theme config builder not available. Please provide callPackage.";
  };
})
