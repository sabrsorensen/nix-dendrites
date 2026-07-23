{ ... }:
{
  flake.modules.nixos.minecraft-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.minecraft {
      networking.firewall.allowedTCPPorts = [ 25565 ];
      environment.systemPackages = [ pkgs.prismlauncher ];
    };
}
