{
  host = {
    primaryInteractiveUser = "sam";
    roles = {
      server = true;
      builder = true;
    };
    deploy = {
      canDeployRemotely = true;
      enableRemoteUser = true;
      sleepy = false;
    };
    ssh.enableNixBlocks = true;
    syncthing.mode = "system";
  };

  services = {
    my.services = {
      apprise.enable = true;
      atuin.enable = true;
      frigate.enable = true;
      immich.enable = true;
      mealie.enable = true;
      monitoring = {
        enable = true;
        basicAuthPasswordEnvVar = "SCRUTINY_PASSWORD";
      };
      samba.enable = true;
      scrutiny.enable = true;
    };
  };
}
