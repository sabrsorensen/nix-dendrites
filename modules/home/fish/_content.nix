args@{ username, ... }:
{
  programs.fish.enable = true;
  home-manager.users.${username}.programs.fish = (import ./_base-content.nix args) // {
    functions = import ./_functions/_content.nix args;
  };
}
