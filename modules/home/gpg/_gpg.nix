{
  inputs,
  isGui,
  isWsl,
  lib,
  pkgs,
  secretRoot ? inputs.nix-secrets,
  ...
}:
let
  gpgKeysDir = "${secretRoot}/gpg-keys";
  ascFiles = builtins.filter (name: lib.hasSuffix ".asc" name) (
    builtins.attrNames (builtins.readDir gpgKeysDir)
  );
in
{
  home.packages = lib.optional isGui pkgs.kdePackages.kleopatra;

  systemd.user.services.gpg-cleanup-stale-locks = {
    Unit = {
      Description = "Remove stale GPG keybox lock files";
      Before = [ "gpg-agent.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find %h/.gnupg -name .#lk* -delete 2>/dev/null; rm -f %h/.gnupg/public-keys.d/pubring.db.lock'";
    };
    Install.WantedBy = [ "gpg-agent.service" ];
  };

  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;
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
    pinentry.package = if isWsl then pkgs.pinentry-curses else pkgs.pinentry-qt;
    extraConfig = ''
      # Allow loopback pinentry for non-interactive scenarios
      allow-loopback-pinentry
      # Better security settings
      default-cache-ttl-ssh 1800
      max-cache-ttl-ssh 7200
    '';
  };
}
