{
  lib,
  package,
  role,
}:
{
  environment.systemPackages = [ package ];

  # Replaces the package's `synergy-service --install`, which links this unit
  # into /etc/systemd/user and enables it globally. The name matters: the GUI
  # and service start it by name with `systemctl --user start synergy-3.service`.
  systemd.user.services.synergy-3 = {
    description = "Synergy 3 background service";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${package}/bin/synergy3-service -d";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  # https://symless.com/synergy/help/what-ports-does-synergy-use
  # 24800: core (the server listens, clients connect out to it).
  # 24802: background-service config sync; 24804: background-service
  # discovery -- both peer-to-peer, so every host listens. Discovery also
  # needs mDNS (UDP 5353).
  networking.firewall = {
    allowedTCPPorts = [
      24802
      24804
    ]
    ++ lib.optional (role == "server") 24800;
    allowedUDPPorts = [ 5353 ];
  };
}
