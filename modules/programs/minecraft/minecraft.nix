{
  pkgs,
  ...
}:
{
  flake.modules.nixos.minecraft = {
    networking.firewall = {
      allowedTCPPorts = [ 25565 ];
    };
    environment.systemPackages = with pkgs; [
      prismlauncher
    ];
  };
}