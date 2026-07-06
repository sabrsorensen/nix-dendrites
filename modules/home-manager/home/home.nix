{
  inputs,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager.home =
    { lib, ... }:
    {
      imports =
        with hm;
        [
          system-default
          bash
          fish
          git
          github-cli
          gpg
          mcp
          nix-index
          shell
          ssh
          starship
          syncthing
          tmux
          vim
          vscode
        ]
        ++ [ hm.host-context ];

      home.sessionVariables = {
        XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";
      };

      programs.home-manager.enable = true;
      programs.man.generateCaches = false;
    };
}
