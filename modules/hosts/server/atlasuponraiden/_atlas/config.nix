{
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
}
