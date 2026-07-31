{
  users.users.sonos = {
    isSystemUser = true;
    group = "media";
  };

  services.postgresql.settings.dynamic_shared_memory_type = "sysv";

  services.samba.settings = {
    global = {
      "server string" = "AtlasUponRaiden Samba";
      "server role" = "standalone server";
      "netbios name" = "atlasuponraiden";
      "hosts allow" = "192.168.1. 127.0.0.1 localhost";
    };
    media = {
      path = "/AnomalyRealm/media/";
      public = "no";
      writable = "yes";
      printable = "no";
      "valid users" = "sam";
    };
    music = {
      path = "/AnomalyRealm/media/music";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "valid users" = "sonos";
      "force user" = "sonos";
    };
  };
}
