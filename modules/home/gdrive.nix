{ inputs, ... }:
{
  # Google Drive is a user service and therefore belongs in Home Manager, but
  # the host fact remains the single broadcast activation boundary.
  flake.modules.nixos.gdrive =
    { config, lib, ... }:
    let
      host = config.my.host;
      username = if host.platform == "wsl" then "ssorensen" else "sam";
      tokenName = "rclone/gdrive/${lib.strings.toLower host.name}_token";
      secretFile = "${inputs.nix-secrets}/rclone/gdrive.yaml";
    in
    lib.mkIf (host.features.gdrive && host.home.enable) {
      home-manager.users.${username} = import ./gdrive/_content.nix {
        inherit secretFile tokenName;
      };
    };
}
