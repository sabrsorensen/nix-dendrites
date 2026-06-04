{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretWrapArgsFromSpecs = import ./secret-wrap-args.nix { inherit lib; };
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
    patches = (prev.patches or [ ]) ++ [ ../modules/home-manager/vscode/openssh-nocheckcfg.patch ];
  });

  patchDesktopItems =
    items:
    lib.map (
      i:
      if i.meta.name == "code-url-handler.desktop" then
        i.overrideAttrs (
          _final: prev: {
            text = lib.strings.replaceStrings [ "StartupWMClass=Code\n" ] [ "" ] prev.text;
          }
        )
      else
        i
    ) items;

  mkBakedVscode =
    package:
    package.overrideAttrs (prev: {
      buildInputs = (prev.buildInputs or [ ]) ++ [ patched-openssh ];
      desktopItems = patchDesktopItems prev.desktopItems;
    });

  selectedBakedTheme = "partyowl84";
  #selectedBakedTheme = "synthwave-blues";
  #selectedBakedTheme = "synthwave-84";

  bakedVscodeByName = {
    "partyowl84" = mkBakedVscode pkgs.vscode-partyowl84;
    "synthwave-blues" = mkBakedVscode pkgs.vscode-synthwave-blues;
    "synthwave-84" = mkBakedVscode pkgs.vscode-synthwave-84;
  };

  baseVscode = bakedVscodeByName.${selectedBakedTheme} or bakedVscodeByName.partyowl84;
  wrappedPackage = pkgs.symlinkJoin {
    pname = baseVscode.pname;
    version = baseVscode.version;
    name = baseVscode.name;
    paths = [ baseVscode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      if [ -f "$out/bin/code" ]; then
        wrapProgram "$out/bin/code"${renderedVscodeSecretWrapArgs}
      fi
      if [ -f "$out/bin/code-url-handler" ]; then
        wrapProgram "$out/bin/code-url-handler"${renderedVscodeSecretWrapArgs}
      fi
    '';
  };
in
{
  inherit selectedBakedTheme;
  package = wrappedPackage;
}
