{
  pkgs,
  ...
}:
{
  flake.modules.nixos.minecraft =
    { pkgs, ... }:
    {
      networking.firewall = {
        allowedTCPPorts = [ 25565 ];
      };
      environment.systemPackages = with pkgs; [
        prismlauncher
      ];
    };
}
