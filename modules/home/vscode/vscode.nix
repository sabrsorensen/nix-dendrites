{ inputs, ... }:
{
  flake-file.inputs = {
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    partyowl84-vscode-theme = {
      url = "github:sabrsorensen/partyowl84-vscode-theme";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-84-vscode-theme = {
      url = "github:sabrsorensen/nix-synthwave-vscode";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-blues-vscode-theme = {
      url = "github:sabrsorensen/synthwave-blues-vscode-theme";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Keep editor packages and Marketplace extension resolution as a normal,
  # self-gating broadcast capability.  The WSL profile continues to manage the
  # Windows-side editor separately.
  flake.modules.nixos.vscode =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      cfg = config.my.editor;
      username = host.home.username;
      package = import ./package/_content.nix {
        inherit
          config
          cfg
          host
          inputs
          lib
          pkgs
          username
          ;
      };
      editorProgram = import ./_profiles-content.nix {
        inherit
          cfg
          lib
          pkgs
          ;
        inherit (host) vscodeTheme;
        inherit (package)
          baseThemePackage
          themePackage
          ;
      };
    in
    {
      options.my.editor = import ./_options-content.nix { inherit lib; };

      config = lib.mkIf (host.features.vscode && host.home.enable) (
        import ./_content.nix (
          args
          // {
            inherit
              cfg
              editorProgram
              inputs
              username
              ;
          }
        )
      );
    };

  flake.modules.nixos.wsl-vscode =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) (
      import ./wsl-vscode/_content.nix (args // { inherit inputs; })
    );
}
