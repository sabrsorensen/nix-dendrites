{ inputs, ... }:
let
  homeModule =
    {
      isSteamDeck ? false,
      nixProfile ? "$HOME/.nix-profile/etc/profile.d/nix.sh",
      ...
    }:
    {
      programs.bash = import ./_bash.nix { inherit isSteamDeck nixProfile; };
    };
  featureModule =
    args@{
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.bash;
    in
    {
      options = {
        my.features.bash = lib.mkEnableOption "Bash";
        my.bash = {
          isSteamDeck = lib.mkEnableOption "Steam Deck Bash profile integration";
          nixProfile = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/.nix-profile/etc/profile.d/nix.sh";
            description = "Nix profile script sourced by the Steam Deck Bash profile.";
          };
        };
      };
      config = lib.mkIf config.my.features.bash (
        homeModule (args // { inherit (cfg) isSteamDeck nixProfile; })
      );
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.bash = featureModule;
}
