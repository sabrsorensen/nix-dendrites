{ lib, ... }:
{
  time.timeZone = lib.mkForce "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  systemd.services = {
    "drkonqi-coredump-launcher@".enable = false;
    "drkonqi-coredump-processor@".enable = false;
  };
  systemd.settings.Manager.DefaultLimitCORE = 0;
  systemd.user.services.gamescope-session = {
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };
}
