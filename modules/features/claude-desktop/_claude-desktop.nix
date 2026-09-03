{ inputs, ... }:
let
  # Systems the upstream flake actually builds a claude-desktop package for.
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
in
{
  flake.modules.nixos.claude-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.claudeDesktop = lib.mkEnableOption "the Claude desktop app";

      config = lib.mkIf config.my.host.features.claudeDesktop {
        assertions = [
          {
            assertion = lib.elem pkgs.stdenv.hostPlatform.system supportedSystems;
            message = "my.host.features.claudeDesktop only supports ${lib.concatStringsSep " / " supportedSystems}; the upstream flake ships no package for ${pkgs.stdenv.hostPlatform.system}.";
          }
        ];

        # The `-with-fhs` variant wraps the app in an FHS env carrying nodejs /
        # uv / docker so it can launch MCP servers via npx / uvx / docker.
        #
        # No my.unfreePackageNames entry: this package is built by the input's
        # own nixpkgs (which sets config.allowUnfree itself), so our unfree gate
        # never evaluates it.
        environment.systemPackages =
          lib.optional (lib.elem pkgs.stdenv.hostPlatform.system supportedSystems)
            (inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs);
      };
    };
}
