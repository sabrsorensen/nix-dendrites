{
  inputs,
  lib,
  ...
}:
let
  hm = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager.sam-home-base =
    { pkgs, ... }:
    {
      imports = with hm; [
        #lazyvim
        sam-git
        sam-secrets
        sam-syncthing
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
