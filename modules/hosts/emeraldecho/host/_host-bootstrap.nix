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
