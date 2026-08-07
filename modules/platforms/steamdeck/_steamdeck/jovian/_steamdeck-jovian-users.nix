{
  config,
  lib,
  ...
}:
{
  users.groups = {
    input = { };
    plugdev = { };
  };
  users.users.${config.jovian.steam.user}.extraGroups =
    lib.mkIf (!builtins.elem "installer" config.my.host.tags)
      (
        lib.mkAfter [
          "networkmanager"
          "audio"
          "video"
        ]
      );
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
