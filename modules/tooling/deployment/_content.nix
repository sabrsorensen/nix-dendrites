{
  config,
  lib,
  pkgs,
  cfg,
  enableRemoteUser,
  isAtlas,
  isWsl,
  atlasBuilder,
  remoteDeployRule,
  ...
}:
let
  hasLocalFlake = cfg.localFlakePath != null;
  useAtlasBuilder = hasLocalFlake && !isWsl && !isAtlas;
in
{
  users.groups = lib.mkIf enableRemoteUser { nix-remote = { }; };
  users.users = lib.mkIf enableRemoteUser {
    nix-remote = {
      isSystemUser = true;
      description = "Nix remote deploy user";
      group = "nix-remote";
      home = "/home/nix-remote";
      createHome = true;
      shell = pkgs.bash;
      hashedPasswordFile = config.sops.secrets.hashed_password.path;
      openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
    };
  };
  systemd.tmpfiles.rules = lib.optionals enableRemoteUser [
    "d /home/nix-remote 0750 nix-remote nix-remote -"
  ];
  security.sudo.extraRules = lib.optionals enableRemoteUser [ remoteDeployRule ];
  nix = {
    distributedBuilds = lib.mkDefault useAtlasBuilder;
    buildMachines = lib.mkDefault (lib.optionals useAtlasBuilder [ atlasBuilder ]);
    settings = {
      trusted-users = lib.mkAfter ([ "@wheel" ] ++ lib.optionals enableRemoteUser [ "nix-remote" ]);
      extra-substituters = lib.mkAfter (
        lib.optionals useAtlasBuilder [
          "ssh-ng://nix-remote@AtlasUponRaiden?ssh-key=/root/.ssh/nix_atlasuponraiden_id_ed25519"
        ]
      );
    };
  };
  programs.nh = lib.mkIf hasLocalFlake {
    enable = true;
    package = pkgs.nh;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = cfg.localFlakePath;
  };
}
