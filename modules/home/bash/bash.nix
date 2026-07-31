{ ... }:
{
  flake.modules.nixos.home-bash =
    {
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
      isSteamDeck = host.platform == "steamdeck";
      nixProfile = "$HOME/.nix-profile/etc/profile.d/nix.sh";
    in
    lib.mkIf host.home.enable {
      home-manager.users.${username}.programs.bash = import ./_content.nix {
        inherit isSteamDeck nixProfile;
      };
    };
}
