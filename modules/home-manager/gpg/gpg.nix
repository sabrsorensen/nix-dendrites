{
  flake.modules.homeManager.gpg =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      gpgKeysDir = config.my.gpgKeysDir;
      # Auto-load all .asc files from gpgKeysDir with ultimate trust
      # Naming convention: <role>-<description>.asc
      #   Roles: signing, encrypt, certify, authenticate (GPG SCEA capabilities)
      #   Examples: signing-personal.asc, signing-singularityci.asc
      gpgFiles = builtins.attrNames (builtins.readDir gpgKeysDir);
      ascFiles = builtins.filter (name: lib.hasSuffix ".asc" name) gpgFiles;
      hostname = osConfig.networking.hostName;
    in
    {
      # Clean stale keyboxd/GPG lock files before gpg-agent starts.
      # After reboot, leftover locks cause "database_open waiting for lock" timeouts.
      systemd.user.services.gpg-cleanup-stale-locks = {
        Unit = {
          Description = "Remove stale GPG keybox lock files";
          Before = [ "gpg-agent.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find %h/.gnupg -name .#lk* -delete 2>/dev/null; rm -f %h/.gnupg/public-keys.d/pubring.db.lock'";
        };
        Install = {
          WantedBy = [ "gpg-agent.service" ];
        };
      };

      programs.gpg = {
        enable = true;
        mutableKeys = true; # Allow manual key management alongside declarative
        mutableTrust = true; # Allow trust level changes
        publicKeys = map (name: {
          source = "${gpgKeysDir}/${name}";
          trust = "ultimate";
        }) ascFiles;
      };

      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        maxCacheTtl = 7200;
        enableFishIntegration = true;
        enableSshSupport = true;
        pinentry.package = if hostname == "NixOS-WSL" then pkgs.pinentry-curses else pkgs.pinentry-qt;
        extraConfig = ''
          # Allow loopback pinentry for non-interactive scenarios
          allow-loopback-pinentry
          # Better security settings
          default-cache-ttl-ssh 1800
          max-cache-ttl-ssh 7200
        '';
      };
    };

}
