{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.sam-home-base =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        firefox
        fish
        github-cli
        #lazyvim
        mcp
        sam-git
        sam-secrets
        sam-syncthing
        tmux
        vim
      ];

      home.username = lib.mkDefault "sam";
      home.homeDirectory = lib.mkDefault "/home/sam";

      home.packages = with pkgs; [
        cowsay
        fortune
        lolcat
        mediainfo
        nerd-fonts.caskaydia-cove
      ];
    };
}
