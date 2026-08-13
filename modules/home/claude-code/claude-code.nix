{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      claudePackage = (pkgs.extend inputs.claude-code.overlays.default).claude-code;
      secretExports =
        lib.concatMapStringsSep "\n"
          (secret: ''
            if [ -r ${lib.escapeShellArg secret.path} ]; then
              export ${secret.name}="$(cat ${lib.escapeShellArg secret.path})"
            fi
          '')
          (
            builtins.filter (secret: secret.path != null) [
              {
                name = "CONTEXT7_API_KEY";
                path = lib.attrByPath [ "sops" "secrets" "context7_api_key" "path" ] null config;
              }
            ]
          );
      wrappedClaude = pkgs.symlinkJoin {
        name = "claude-code-wrapped-${lib.getVersion claudePackage}";
        paths = [ claudePackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/claude" --run ${lib.escapeShellArg secretExports}
        '';
      };
    in
    {
      options.my.features.claudeCode = lib.mkEnableOption "Claude Code";
      config = lib.mkIf config.my.features.claudeCode {
        programs.claude-code = {
          enable = true;
          package = wrappedClaude;
        };
      };
    };
in
{
  flake-file.inputs.claude-code = {
    url = "github:sadjow/claude-code-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.claude-code = homeModule;

  flake.modules.nixos.claude-code =
    { lib, ... }:
    {
      options.my.host.features.claudeCode = lib.mkEnableOption "Claude Code";
    };
}
