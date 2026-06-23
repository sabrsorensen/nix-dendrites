{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.my.media.enable {
    systemd.services."podman-network-media" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f ${config.my.media.podmanNetwork}";
      };
      script = ''
        podman network inspect ${config.my.media.podmanNetwork} || podman network create ${config.my.media.podmanNetwork} --driver=bridge
      '';
      wantedBy = [ "multi-user.target" ];
    };
  };
}
