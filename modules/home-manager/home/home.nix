{
  inputs,
  ...
}:
{
  flake.modules.homeManager.home =
    { ... }:
    {
      imports =
        with inputs.self.modules.homeManager;
        [
          system-default
          bash
          git
          gpg
          nix-index
          shell
          ssh
          starship
          syncthing
        ]
        ++ [ inputs.self.modules.homeManager.host-context ];

      home.sessionVariables = {
        XDG_CONFIG_HOME = "$HOME/.config";
      };

      programs.home-manager.enable = true;
      programs.man.generateCaches = false;
    };
}
