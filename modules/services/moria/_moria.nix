{
  config,
  dataDir,
  lib,
  port,
  serviceName,
  ...
}:
{
  assertions = [
    {
      assertion = config.my.host.features.podman;
      message = "The Moria server relies on Podman's --health-on-failure; enable features.podman.";
    }
  ];

  # The image runs steamcmd + Wine on every start, then drops to uid 1000
  # (the image's build-time "steam" user, which keeps the fast symlinked
  # Wine prefix path).  MoriaServerConfig.ini / Permissions / Rules are
  # written into ${dataDir} on first start and edited in place there --
  # they're not managed declaratively.  Saves live under
  # ${dataDir}/Moria/Saved/SaveGamesDedicated.
  systemd.tmpfiles.rules = [ "d ${dataDir} 0750 1000 1000 -" ];

  # Clients join over raw UDP (Direct Join: moria.<domain>:7777), so this is
  # a DNS name only -- there's no HTTP surface for a Caddy route to proxy.
  my.localDns.records = [ { hostname = serviceName; } ];

  networking.firewall.allowedUDPPorts = [ port ];

  virtualisation.oci-containers.containers.${serviceName} = {
    autoStart = true;
    image = "docker.io/andrewsav/moria:1.4.1";
    volumes = [ "${dataDir}:/server:rw" ];
    # ListenPort inside MoriaServerConfig.ini must stay 7777 (the image's
    # healthcheck probes it); change only the host side, plus AdvertisePort.
    ports = [ "${lib.toString port}:7777/udp" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=${serviceName}"
      # The server only cleans up its EOS session on SIGINT; without a
      # graceful stop the next start fails until the session expires (~5m).
      "--stop-signal=SIGINT"
      # Stays under the unit's TimeoutStopSec (120s).
      "--stop-timeout=90"
      # Console access: `podman attach moria`, detach with ctrl-p ctrl-q.
      "--interactive"
      "--tty"
      # The server exits/hangs when Epic Online Services drops; the image's
      # UDP healthcheck notices and Podman restarts the container.  The
      # image's 5m start period is too short for the first steamcmd
      # download, so widen it.
      "--health-on-failure=restart"
      "--health-start-period=15m"
    ];
  };
}
