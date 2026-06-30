{
  config,
  ...
}:
{
  users.users.sam.hashedPasswordFile = config.sops.secrets.hashed_password.path;
  users.users.sam.extraGroups = [ "video" ];
  users.users.root.extraGroups = [ "video" ];

  services.udev.extraRules = ''
    SUBSYSTEM=="vchiq", GROUP="video", MODE="0664"
    SUBSYSTEM=="vcio", GROUP="video", MODE="0664"
    SUBSYSTEM=="vcsm", GROUP="video", MODE="0664"
  '';

  security.sudo.extraRules = [
    {
      users = [ "sam" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/vcgencmd *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
