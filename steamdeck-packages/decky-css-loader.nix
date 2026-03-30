{
  lib,
  fetchFromGitHub,
  nodejs,
  pnpm_9,
  fetchPnpmDeps,
  pnpmConfigHook,
  python3,
  stdenv,
  writeText,
  themeConfig ? null,
  callPackage ? null,
}:

let
  cssThemeConfigBuilder =
    if callPackage != null then callPackage ./css-theme-config-simple.nix { } else null;

in
stdenv.mkDerivation rec {
  pname = "decky-css-loader";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "suchmememanyskill";
    repo = "SDH-CssLoader";
    rev = "v${version}";
    sha256 = "sha256-dEhK1LcOMerSQsOiUahMm/RX78ABNsKReQfRfspyw68=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    pnpm = pnpm_9;
    fetcherVersion = 3;
    hash = "sha256-cdKYY2+1wJR7ME7Tj0FZnhP00nrsUetcxbjFZGbGZfg=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9
    pnpmConfigHook
    python3
  ];

  postPatch = ''
    cp ${./patches/decky-css-loader-main.py} main.py
  '';

  # Symlink-to-copy patch for NixOS compatibility (if needed)
  patchScript = writeText "nixos-symlink-fix.py" ''
    #!/usr/bin/env python3
    import os
    import re
    import glob

    def patch_python_files():
        python_files = glob.glob("**/*.py", recursive=True)
        for filepath in python_files:
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                original_content = content

                if 'os.symlink' in content and 'import shutil' not in content:
                    content = re.sub(r'(import os\n)', r'\1import shutil\n', content)

                content = re.sub(
                    r'os\.symlink\s*\(\s*([^,]+),\s*([^)]+)\s*\)',
                    r'shutil.copy2(\1, \2); os.chmod(\2, 0o644)',
                    content
                )

                content = re.sub(
                    r'os\.link\s*\(\s*([^,]+),\s*([^)]+)\s*\)',
                    r'shutil.copy2(\1, \2)',
                    content
                )

                if content != original_content:
                    with open(filepath, 'w') as f:
                        f.write(content)
                    print(f"Patched {filepath}")
            except Exception as e:
                print(f"Error patching {filepath}: {e}")

    if __name__ == "__main__":
        patch_python_files()
  '';

  preConfigure = ''
    # Apply NixOS symlink compatibility patch
    python3 ${patchScript}
    echo "Applied potential NixOS symlink compatibility patch"
  '';

  buildPhase = ''
    runHook preBuild

    echo "Building CSS Loader frontend..."
    pnpm build

    if [ ! -f dist/index.js ]; then
      echo "Error: Frontend build failed - dist/index.js not found"
      exit 1
    fi

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out/

    # Verify required plugin files exist
    if [ ! -f $out/main.py ]; then
      echo "Error: Plugin must contain a main.py file"
      exit 1
    fi
    if [ ! -f $out/plugin.json ]; then
      echo "Error: Plugin must contain a plugin.json file"
      exit 1
    fi

    ${lib.optionalString (themeConfig != null) ''
      cp ${themeConfig} $out/nix-css-themes.json
    ''}

    # Set proper permissions
    find $out -type f -exec chmod 644 {} \;                # Default: read-write for files
    find $out -type d -exec chmod 755 {} \;                # Default: executable for directories

    # Restore execute permissions for scripts
    find $out -type f -name "*.py" -exec chmod +x {} \;    # Python scripts
    find $out -type f -name "*.sh" -exec chmod +x {} \;    # Shell scripts
    find $out -type f -path "*/bin/*" -exec chmod +x {} \; # All bin scripts

    runHook postInstall
  '';

  passthru = {
    inherit cssThemeConfigBuilder;

    withThemeConfig =
      themeConfig:
      stdenv.mkDerivation rec {
        inherit
          pname
          version
          src
          pnpmDeps
          nativeBuildInputs
          postPatch
          patchScript
          preConfigure
          buildPhase
          ;

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r * $out/

          if [ ! -f $out/main.py ]; then
            echo "Error: Plugin must contain a main.py file"
            exit 1
          fi
          if [ ! -f $out/plugin.json ]; then
            echo "Error: Plugin must contain a plugin.json file"
            exit 1
          fi

          cp ${themeConfig} $out/nix-css-themes.json

          find $out -type f -exec chmod 644 {} \;
          find $out -type d -exec chmod 755 {} \;
          find $out -type f -name "*.py" -exec chmod +x {} \;
          find $out -type f -name "*.sh" -exec chmod +x {} \;
          find $out -type f -path "*/bin/*" -exec chmod +x {} \;

          runHook postInstall
        '';
      };

    withThemes =
      args:
      if cssThemeConfigBuilder != null then
        (stdenv.mkDerivation rec {
          inherit
            pname
            version
            src
            pnpmDeps
            nativeBuildInputs
            postPatch
            patchScript
            preConfigure
            buildPhase
            ;

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp -r * $out/

            if [ ! -f $out/main.py ]; then
              echo "Error: Plugin must contain a main.py file"
              exit 1
            fi
            if [ ! -f $out/plugin.json ]; then
              echo "Error: Plugin must contain a plugin.json file"
              exit 1
            fi

            cp ${cssThemeConfigBuilder.buildNixCssThemeConfig args} $out/nix-css-themes.json

            find $out -type f -exec chmod 644 {} \;
            find $out -type d -exec chmod 755 {} \;
            find $out -type f -name "*.py" -exec chmod +x {} \;
            find $out -type f -name "*.sh" -exec chmod +x {} \;
            find $out -type f -path "*/bin/*" -exec chmod +x {} \;

            runHook postInstall
          '';
        })
      else
        throw "CSS theme config builder not available. Please provide callPackage.";
  };

  meta = with lib; {
    description = "CSS theme loader for Steam Deck";
    homepage = "https://github.com/suchmememanyskill/SDH-CssLoader";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
