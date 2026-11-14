{
  config,
  lib,
  pkgs,
}:
let
  cfg = config.services.clamav;

  normalUserHomes = lib.mapAttrsToList (_: user: user.home) (
    lib.filterAttrs (_: user: user.isNormalUser) config.users.users
  );

  # Where files from outside arrive: browser downloads and the phone's
  # Syncthing drop folder. The rest of /home (games, Wine prefixes, media,
  # source trees) is not scanned -- re-reading hundreds of GB daily pinned
  # every core for hours and mostly turned up third-party-signature false
  # positives in Wine/mono binaries.
  untrustedHomeDirs = lib.concatMap (home: [
    "${home}/Downloads"
    "${home}/mobile_downloads"
  ]) normalUserHomes;

  # Not every host/user has every directory, and clamdscan exits non-zero
  # (failing the unit) on a missing path, so only pass the ones that exist.
  clamdscanExisting = pkgs.writeShellApplication {
    name = "clamdscan-existing";
    runtimeInputs = [ cfg.package ];
    text = ''
      dirs=()
      for dir in "$@"; do
        if [ -e "$dir" ]; then
          dirs+=("$dir")
        fi
      done
      if [ "''${#dirs[@]}" -eq 0 ]; then
        echo "clamdscan: none of the configured scan directories exist; nothing to do"
        exit 0
      fi
      exec clamdscan --multiscan --fdpass --infected --allmatch "''${dirs[@]}"
    '';
  };
in
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
        # clamdscan --multiscan fans out one file per clamd thread (default
        # 10). Two is plenty for the small download/temp scan set and keeps
        # the scan from taking over the machine.
        MaxThreads = 2;
        # Regexes; clamdscan honours these while walking scanDirectories.
        ExcludePath = [
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
      # Daily at 04:00 (nixpkgs default interval). Only download/untrusted
      # locations: not /etc (Nix-generated) and not /var/lib (on Atlas that is
      # databases and service state). Nextcloud's datadir holds user uploads.
      scanDirectories = [
        "/tmp"
        "/var/tmp"
      ]
      ++ untrustedHomeDirs
      ++ lib.optional config.my.host.services.nextcloud config.services.nextcloud.datadir;
    };
  };

  # clamd does the actual scanning (clamdscan --fdpass only hands it file
  # descriptors), so the throttling has to live on the daemon, not just on
  # clamdscan. Not CPUSchedulingPolicy=idle: clamd also serves on-demand
  # scans, which shouldn't starve indefinitely under sustained load.
  systemd.services.clamav-daemon.serviceConfig = {
    Nice = 19;
    IOSchedulingClass = "idle";
    CPUWeight = 20;
    IOWeight = 20;
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
      ExecStart = lib.mkForce "${lib.getExe clamdscanExisting} ${lib.escapeShellArgs cfg.scanner.scanDirectories}";
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
