{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  python3,
  writeText,
  themeConfig ? null,
  callPackage ? null,
}:

let
  cssThemeConfigBuilder =
    if callPackage != null then callPackage ./css-theme-config-simple.nix { } else null;

  patchScript = writeText "decky-css-loader-nixos-fix.py" ''
    #!/usr/bin/env python3
    import pathlib

    target = pathlib.Path("css_utils.py")

    if not target.exists():
        print("css_utils.py not found; skipping NixOS compatibility patch")
        raise SystemExit(0)

    content = target.read_text(encoding="utf-8")
    original = content

    if "import shutil" not in content:
        content = content.replace("import os", "import os\nimport shutil", 1)

    content = content.replace("os.symlink(", "shutil.copy2(")
    content = content.replace("os.link(", "shutil.copy2(")

    if content != original:
        target.write_text(content, encoding="utf-8")
        print("Patched css_utils.py for copy-based theme installation")
    else:
        print("css_utils.py already compatible; no patch applied")
  '';

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
      preConfigure = ''
        python3 ${patchScript}
      '';
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
