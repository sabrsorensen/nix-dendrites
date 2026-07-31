{ inputs, lib, ... }:
let
  rootLuksUuid = lib.removeSuffix "\n" (
    builtins.readFile "${inputs.nix-secrets}/luks/zaphod/root.txt"
  );
in
{
  flake.modules.nixos.hardware-zaphodbeeblebrox =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.name == "ZaphodBeeblebrox") (
      import ./_content.nix (args // { inherit rootLuksUuid; })
    );
}
