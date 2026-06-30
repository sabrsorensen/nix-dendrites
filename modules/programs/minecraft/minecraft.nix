{
  pkgs,
  ...
}:
{
  flake.modules.nixos.minecraft =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.minecraft {
      networking.firewall = {
        allowedTCPPorts = [ 25565 ];
      };
      environment.systemPackages = with pkgs; [
        prismlauncher
      ];
    };
}
