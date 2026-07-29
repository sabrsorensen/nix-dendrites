{ inputs, ... }:
{
  flake.modules.nixos.nix-index = { lib, ... }: {
    programs.command-not-found.enable = lib.mkDefault false;
  };

  flake.modules.homeManager.nix-index = { pkgs, ... }: {
    imports = [ inputs.nix-index-database.homeModules.nix-index ];
    programs.nix-index = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
    programs.command-not-found.enable = false;
    home.packages = [ pkgs.comma ];
  };
}
