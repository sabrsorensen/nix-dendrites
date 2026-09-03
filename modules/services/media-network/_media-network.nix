{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    assertions =
      let
        identities = builtins.attrValues config.my.media.containerIdentities;
        uids = map (identity: identity.uid) identities;
      in
      [
        {
          assertion = lib.length uids == lib.length (lib.unique uids);
          message = "my.media.containerIdentities must assign a unique UID to each service.";
        }
      ];
  }
  (lib.mkIf (config.my.host.services.deluge || config.my.host.services.watchtower) {
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
  })
]
