{
  inputs,
  ...
}:
{
  flake.modules.homeManager.nix-index =
    { lib, pkgs, config, ... }:
    {
      # Import the nix-index-database Home Manager module within Home Manager context
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      # Enable nix-index with pre-built database
      programs.nix-index = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };

      # Disable command-not-found since nix-index provides this functionality
      programs.command-not-found.enable = false;

      # Add comma for easy temporary package usage
      home.packages = with pkgs; [
        comma
      ];
    };

  flake.modules.nixos.nix-index =
    { lib, ... }:
    {
      # Disable system-wide command-not-found since Home Manager nix-index provides this
      programs.command-not-found.enable = lib.mkDefault false;

      # Enable nix-command and flakes features required for comma
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
}