{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.my.services.media.enable {
    systemd.services."podman-network-media" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f ${config.my.services.media.podmanNetwork}";
      };
      script = ''
        podman network inspect ${config.my.services.media.podmanNetwork} || podman network create ${config.my.services.media.podmanNetwork} --driver=bridge
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
