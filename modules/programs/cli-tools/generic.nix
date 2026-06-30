let
  genericPackages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages =
        with pkgs;
        [
          git
          tmux
          home-manager
          cowsay
        ]
        ++ lib.optionals (config.my.host.deploy.localFlakePath != null) [ just ];
    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };
}
