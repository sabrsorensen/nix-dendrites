{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  secretWrapArgsFromSpecs = inputs.self.lib.shared.secretWrapArgsFromSpecs;
  product = import ./_product.nix {
    flavor = config.my.editor.packageFlavor;
  };
  context7ApiKeyPath =
    if config.sops.secrets ? context7_api_key then config.sops.secrets.context7_api_key.path else null;

  githubMcpTokenPath =
    if config.sops.secrets ? github_nixos_mcp_token then
      config.sops.secrets.github_nixos_mcp_token.path
    else
      null;

  vscodeSecretWrapArgs = secretWrapArgsFromSpecs [
    {
      envName = "GITHUB_NIXOS_MCP_TOKEN";
      secretPath = githubMcpTokenPath;
    }
    {
      envName = "CONTEXT7_API_KEY";
      secretPath = context7ApiKeyPath;
    }
  ];

  renderedVscodeSecretWrapArgs = lib.optionalString (vscodeSecretWrapArgs != [ ]) ''
            \
    ${lib.concatStringsSep " \\\n          " vscodeSecretWrapArgs}
  '';

  patched-openssh = pkgs.openssh.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [ ./openssh-nocheckcfg.patch ];
  });

  patchDesktopItems =
    items:
    lib.map (
      i:
      if i.meta.name == product.urlHandlerDesktopName then
        i.overrideAttrs (
          _final: prev: {
            text =
              lib.strings.replaceStrings [ "StartupWMClass=Code\n" "StartupWMClass=VSCodium\n" ] [ "" "" ]
                prev.text;
          }
        )
      else
        i
    ) items;

  mkEditorPackage =
    package:
    package.overrideAttrs (prev: {
      buildInputs = (prev.buildInputs or [ ]) ++ [ patched-openssh ];
      desktopItems = patchDesktopItems prev.desktopItems;
    });

  selectedTheme = "partyowl84";
  #selectedTheme = "synthwave-blues";
  #selectedTheme = "synthwave-84";

  bakedPackageByFlavor = {
    vscode = {
      "partyowl84" = mkEditorPackage pkgs.vscode-partyowl84;
      "synthwave-blues" = mkEditorPackage pkgs.vscode-synthwave-blues;
      "synthwave-84" = mkEditorPackage pkgs.vscode-synthwave-84;
    };
    vscodium = {
      "partyowl84" = mkEditorPackage pkgs.vscodium-partyowl84;
      "synthwave-blues" = mkEditorPackage pkgs.vscodium-synthwave-blues;
      "synthwave-84" = mkEditorPackage pkgs.vscodium-synthwave-84;
    };
  };

  basePackage =
    bakedPackageByFlavor.${config.my.editor.packageFlavor}.${selectedTheme}
      or bakedPackageByFlavor.vscodium.partyowl84;
  wrappedPackage = pkgs.symlinkJoin {
    pname = basePackage.pname;
    version = basePackage.version;
    name = basePackage.name;
    paths = [ basePackage ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      if [ -f "$out/bin/${product.binaryName}" ]; then
        wrapProgram "$out/bin/${product.binaryName}"${renderedVscodeSecretWrapArgs}
      fi
      if [ -f "$out/bin/${product.urlHandlerBinaryName}" ]; then
        wrapProgram "$out/bin/${product.urlHandlerBinaryName}"${renderedVscodeSecretWrapArgs}
      fi
    '';
  };
in
{
  inherit selectedTheme;
  package = wrappedPackage;
}
