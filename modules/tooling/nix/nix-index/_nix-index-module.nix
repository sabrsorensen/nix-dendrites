{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      options.my.features."nix-index" = lib.mkEnableOption "Nix-index";

      config = lib.mkIf config.my.features."nix-index" {
        programs.nix-index = {
          enable = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;
        };
        programs.command-not-found.enable = false;
        home.packages = [ pkgs.comma ];
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];

  flake.modules.nixos.nix-index = { lib, ... }: {
    programs.command-not-found.enable = lib.mkDefault false;
  };

  flake.modules.homeManager.nix-index = homeModule;
}
