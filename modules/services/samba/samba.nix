{
  flake.modules.nixos.samba =
    { pkgs, ... }:
    {
      services.samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            security = "user";
            "workgroup" = "MYGROUP";
            "dns proxy" = "yes";
            "logging" = "systemd";
          };
        };
      };

      services.samba-wsdd = {
        enable = true;
        openFirewall = true;
      };

      networking.firewall.enable = true;
      networking.firewall.allowPing = true;
    };
}
