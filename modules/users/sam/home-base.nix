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
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = with hm; [
        #lazyvim
        sam-git
        sam-secrets
        sam-syncthing
      ];

      home.username = lib.mkDefault "sam";
      home.homeDirectory = lib.mkDefault "/home/sam";

      home.packages =
        with pkgs;
        [
          cowsay
          fortune
          lolcat
          mediainfo
          nerd-fonts.caskaydia-cove
        ]
        ++ lib.optionals (config.my.host.features.gui && !config.my.host.is.wsl) [
          clementine
          discord
          ferdium
          plex-desktop
          signal-desktop
          vlc
        ];
    };
}
