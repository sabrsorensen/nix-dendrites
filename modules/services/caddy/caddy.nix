{
  inputs,
  ...
}:
{
  flake.modules.nixos.caddy = {
    imports = [
      (import ./_caddy-service.nix { inherit inputs; })
      (import ./_fail2ban.nix { })
    ];
  };
}
