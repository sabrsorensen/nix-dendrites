{
  lib,
  package,
  role,
}:
let
  account = "synergy-dragon";
in
{
  environment.systemPackages = [ package ];

  # The package's post-install creates this account; the service drops to it
  # rather than running as root.
  users.users.${account} = {
    isSystemUser = true;
    group = account;
    home = "/var/lib/${account}";
    description = "Synergy 4 Dragon Beta";
  };
  users.groups.${account} = { };

  # Mirrors the package's etc/systemd/system/synergy-dragon.service, enabled
  # as its system preset does.
  systemd.services.synergy-dragon = {
    description = "Synergy 4 Dragon Beta service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
    serviceConfig = {
      Type = "exec";
      User = account;
      Group = account;
      EnvironmentFile = "-/etc/synergy-dragon/service.env";
      # The package's post-install seeds /var/lib/synergy-dragon/versions from
      # the installed binaries before the service first starts; the launcher
      # runs whichever version that tree points at (and self-updates into it).
      ExecStartPre = "${package}/bin/synergy-dragon-service seed";
      ExecStart = "${package}/bin/synergy-dragon-launcher";
      # Quitting from the app is a clean exit; anything else brings it back.
      Restart = "on-failure";
      RestartSec = 2;
      RuntimeDirectory = account;
      RuntimeDirectoryMode = "0755";
      StateDirectory = account;
      StateDirectoryMode = "0755";
      ProtectSystem = "full";
    };
  };

  # Mirrors usr/lib/systemd/user/synergy-dragon-agent.service, enabled as its
  # user preset does. The package's XDG autostart entry is deliberately not
  # installed: it only exists to start this unit on desktops without one.
  systemd.user.services.synergy-dragon-agent = {
    description = "Synergy 4 Dragon Beta session agent";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
    serviceConfig = {
      Type = "exec";
      ExecStart = "${package}/bin/synergy-dragon-agent";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # From usr/share/polkit-1/rules.d/49-synergy-dragon.rules: whoever is signed
  # in at the machine may start (only start) the service after quitting it
  # from the tray.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (
        action.id === "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") === "synergy-dragon.service" &&
        action.lookup("verb") === "start" &&
        subject.local &&
        subject.active
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  # Symless doesn't document Synergy 4's ports yet. The core still listens on
  # 24800 on the server; discovery uses mDNS (_dns-sd._udp).
  networking.firewall = {
    allowedTCPPorts = lib.optional (role == "server") 24800;
    allowedUDPPorts = [ 5353 ];
  };
}
