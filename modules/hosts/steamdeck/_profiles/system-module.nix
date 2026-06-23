{
  inputs,
  descriptor,
  lib,
  host,
  steamdeck,
}:
bootMode:
{ config, pkgs, ... }:
let
  mkBaseModule = import ./base-module.nix { inherit descriptor host; };
  sshKeyHelpers = import ../../_ssh-key-helpers.nix { inherit config; };
  steamUser = host.users.steam.name;
in
mkBaseModule {
  inherit bootMode;
  lifecycle = "system";
  extraImports =
    descriptor.nixos.imports
    ++ (with inputs.self.modules.nixos; [
      system-cli
      disko
      deploy-defaults
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.jovian-nixos.nixosModules.default
      steamdeck-decky-plugins
      (steamdeck.mkDeckyModule { inherit steamUser; })
      steamdeck-plugins
      (steamdeck.mkHwConfig bootMode)
      (steamdeck.mkSteamModule { inherit steamUser; })
      steamdeck-system
    ]);
  extraConfig = {
    my.host.deploy.enableRemoteUser = true;

    users.users.${steamUser} = {
      isNormalUser = true;
      extraGroups = host.users.steam.extraGroups;
      uid = lib.mkForce 1000;
      hashedPasswordFile = config.sops.secrets.hashed_password.path;
      openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles host.users.steam.authorizedKeyPaths;
    };

    users.groups.${steamUser}.gid = lib.mkForce 1000;

    users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
      openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles host.users.nixRemote.authorizedKeyPaths;
    };

    home-manager.users.${steamUser}.imports = [
      inputs.self.modules.homeManager.${descriptor.home.moduleName}
    ];

    networking.firewall.allowedTCPPorts = [
      1400
      3400
      24800
    ];
    networking.firewall.allowedUDPPorts = [ 24800 ];

    environment.systemPackages = host.systemPackages pkgs;
    services.flatpak.packages = [
      "io.github.Geocld.XStreamingDesktop"
      "io.github.unknownskl.greenlight"
    ];

    programs.kdeconnect.enable = true;
  };
}
