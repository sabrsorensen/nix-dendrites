{ cfg, lib, ... }:
{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = lib.recursiveUpdate {
      global = {
        security = "user";
        "workgroup" = "MYGROUP";
        "dns proxy" = "yes";
        "logging" = "systemd";
      };
    } cfg.settings;
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
  };
}
