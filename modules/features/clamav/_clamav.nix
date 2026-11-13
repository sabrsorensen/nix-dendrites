{ config, lib }:
{
  # The nixpkgs module already adds services.clamav.package to
  # environment.systemPackages when the daemon or updater is enabled.
  services.clamav = {
    daemon = {
      enable = true;
      settings = {
        # Don't hold a second copy of the signature DB in RAM while reloading
        # after a freshclam/fangfrisch update; scans just wait for the reload.
        ConcurrentDatabaseReload = false;
        # Regexes; clamdscan honours these while walking scanDirectories.
        ExcludePath = [
          # Installed game files: hundreds of GB, re-read daily for little gain.
          "/steamapps/(common|shadercache|downloading|temp)/"
          "^/home/[^/]+/\\.cache/"
          # Rootless podman image layers.
          "^/home/[^/]+/\\.local/share/containers/"
          # Nextcloud-generated thumbnails.
          "/appdata_[^/]+/preview/"
        ];
      };
    };
    updater.enable = true;

    # Third-party signatures on top of the official DB. Sanesecurity is free and
    # needs no key (the nixpkgs default provider set).
    fangfrisch.enable = true;

    scanner = {
      enable = true;
      # Daily at 04:00 (nixpkgs default interval). Not /var/lib: on Atlas that is
      # databases and service state, not user-supplied files.
      scanDirectories = [
        "/home"
        "/tmp"
        "/var/tmp"
        "/etc"
      ]
      ++ lib.optional config.my.host.services.nextcloud config.services.nextcloud.datadir;
    };
  };

  # Laptops and the Deck are usually asleep at 04:00: catch up after wake, but
  # skip while on battery (servers have no battery, so the condition holds).
  systemd.timers.clamdscan.timerConfig = {
    Persistent = true;
    RandomizedDelaySec = "30m";
  };
  systemd.services.clamdscan = {
    unitConfig.ConditionACPower = true;
    serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
  };

  # Keep the signature databases (official + fangfrisch) across root rollbacks
  # so they aren't re-fetched on every boot.
  environment.persistence = lib.mkIf (
    config.my.host.features.persistenceSystem && !config.my.host.persistence.varOnOwnSubvolumes
  ) { "/persist".directories = [ "/var/lib/clamav" ]; };
}
