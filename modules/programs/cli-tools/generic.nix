{ inputs, ... }:
let
  genericPackages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      hasLocalFlake = config.my.host.deploy.localFlakePath != null;
      localFlakeToolPackages = lib.optionals hasLocalFlake [
        pkgs.just
        inputs.self.formatter.${system}
        inputs.self.packages.${system}.write-flake
        inputs.self.packages.${system}.write-inputs
        inputs.self.packages.${system}.write-lock
      ];
    in
    {
      environment.systemPackages =
        with pkgs;
        [
          git
          tmux
          home-manager
          cowsay
        ]
        ++ localFlakeToolPackages;
    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };
}
