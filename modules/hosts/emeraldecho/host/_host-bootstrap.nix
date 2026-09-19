{
  baseModule,
  finalConfigName,
  lib,
  tags,
}:
lib.recursiveUpdate baseModule {
  my.host.tags = tags;
  my.host.home.enable = false;
  my.host.bootstrap.finalConfigName = finalConfigName;
  my.deployment.enableRemoteUser = false;
  # Mirror the installer's override (_host-installer.nix) -- the bootstrap
  # config exists to get a minimal, secrets-less machine reachable over SSH,
  # so it shouldn't also fetch and build the full Decky plugin catalog.
  jovian.decky-loader.enable = lib.mkForce false;
  users.users.sam = {
    isNormalUser = true;
    description = "Sam";
    group = "sam";
    uid = lib.mkForce 1000;
    extraGroups = [ "wheel" ];
    initialPassword = lib.mkForce "jovian";
    hashedPasswordFile = lib.mkForce null;
  };
  users.groups.sam.gid = lib.mkForce 1000;
  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce true;
    KbdInteractiveAuthentication = lib.mkForce false;
  };
}
