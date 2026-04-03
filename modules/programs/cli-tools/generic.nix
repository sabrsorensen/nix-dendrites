let
  genericPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        tmux
        home-manager
        cowsay
      ];
    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };
}
