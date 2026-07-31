{ ... }:
{
  flake.modules.nixos.home-mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
    in
    lib.mkIf host.home.enable {
      home-manager.users.${username} = lib.mkMerge [
        (lib.mkIf (host.features.mcpCommon || host.platform == "wsl") (
          import ./_content.nix { inherit lib; }
        ))
        (lib.mkIf host.features.personalMcpServers (import ./_personal-content.nix { inherit pkgs; }))
        (lib.mkIf (host.platform == "wsl") (import ./_work-content.nix { }))
      ];
    };
}
