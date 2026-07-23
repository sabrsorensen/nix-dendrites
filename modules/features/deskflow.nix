{ ... }:
{
  flake.modules.nixos.deskflow =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.deskflow {
      environment.systemPackages = [ pkgs.deskflow ];
      networking.firewall = {
        allowedTCPPorts = [ 24800 ];
        allowedUDPPorts = [ 24800 ];
      };
      services.xserver.xkb = {
        layout = lib.mkDefault "us";
        variant = lib.mkDefault "";
      };
    };
}
