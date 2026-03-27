{
  inputs,
  ...
}:
{
  flake.modules.homeManager.home =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        system-default
        bash
        fish
        git
        github-cli
        gpg
        shell
        ssh
        starship
        syncthing
        tmux
        vim
      ];

      home.sessionVariables = {
        XDG_CONFIG_HOME = "$HOME/.config";
      };

      home.packages = with pkgs; [
        cowsay
        fortune
        lolcat
        mediainfo
        nerd-fonts.caskaydia-cove
      ];

      programs.home-manager.enable = true;
      programs.man.generateCaches = false;
    };
}
