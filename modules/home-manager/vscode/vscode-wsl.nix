{
  flake.modules.homeManager."vscode-wsl" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.vscode.package = lib.mkForce (
        pkgs.stdenv.mkDerivation {
          pname = "vscode-sync-placeholder";
          version = "1.0.0";
          src = pkgs.emptyDirectory;

          installPhase = ''
                        mkdir -p "$out/lib/vscode/resources/app"
                        cat > "$out/lib/vscode/resources/app/product.json" <<'EOF'
            {
              "nameShort": "Code",
              "nameLong": "Visual Studio Code",
              "applicationName": "code",
              "dataFolderName": ".vscode"
            }
            EOF
          '';

          fixupPhase = "";

          meta = with lib; {
            description = "VS Code placeholder for WSL that allows Home Manager settings sync";
            platforms = platforms.all;
          };
        }
      );
    };
}
