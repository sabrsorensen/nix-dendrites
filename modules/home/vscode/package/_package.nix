{
  config,
  cfg,
  inputs,
  lib,
  pkgs,
  vscodeTheme,
  ...
}:
let
  theme = vscodeTheme;
  baseThemePackage =
    {
      partyowl84 = {
        vscode =
          inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-partyowl84;
        vscodium =
          inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-partyowl84;
      };
      synthwave-blues = {
        vscode =
          inputs.synthwave-blues-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-synthwave-blues;
        vscodium =
          inputs.synthwave-blues-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-synthwave-blues;
      };
      synthwave-84 = {
        vscode =
          inputs.synthwave-84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-synthwave84;
        vscodium =
          inputs.synthwave-84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-synthwave84;
      };
    }
    .${theme}.${cfg.packageFlavor};
  product =
    {
      vscode = {
        binaryName = "code";
        urlHandlerBinaryName = "code-url-handler";
        urlHandlerDesktopName = "code-url-handler.desktop";
      };
      vscodium = {
        binaryName = "codium";
        urlHandlerBinaryName = "codium-url-handler";
        urlHandlerDesktopName = "codium-url-handler.desktop";
      };
    }
    .${cfg.packageFlavor};
  patchedOpenSsh = pkgs.openssh.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./assets/openssh-nocheckcfg.patch ];
  });
  patchDesktopItems =
    items:
    map (
      item:
      if item.meta.name == product.urlHandlerDesktopName then
        item.overrideAttrs (
          _: prev: {
            text =
              builtins.replaceStrings [ "StartupWMClass=Code\n" "StartupWMClass=VSCodium\n" ] [ "" "" ]
                prev.text;
          }
        )
      else
        item
    ) items;
  editorPackage = baseThemePackage.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ patchedOpenSsh ];
    desktopItems = patchDesktopItems old.desktopItems;
  });
  editorSecretExports =
    lib.concatMapStringsSep "\n"
      (secret: ''
        if [ -r ${lib.escapeShellArg secret.path} ]; then
          export ${secret.name}="$(cat ${lib.escapeShellArg secret.path})"
        fi
      '')
      (
        builtins.filter (secret: secret.path != null) [
          {
            name = "GITHUB_NIXOS_MCP_TOKEN";
            path = lib.attrByPath [ "sops" "secrets" "github_nixos_mcp_token" "path" ] null config;
          }
          {
            name = "CONTEXT7_API_KEY";
            path = lib.attrByPath [ "sops" "secrets" "context7_api_key" "path" ] null config;
          }
        ]
      );
  themePackage = pkgs.symlinkJoin {
    name = "${baseThemePackage.pname or baseThemePackage.name}-wrapped";
    paths = [ editorPackage ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for binary in ${product.binaryName} ${product.urlHandlerBinaryName}; do
        if [ -f "$out/bin/$binary" ]; then
          wrapProgram "$out/bin/$binary" --run ${lib.escapeShellArg editorSecretExports}
        fi
      done
    '';
  };
in
{
  inherit
    baseThemePackage
    product
    themePackage
    ;
}
