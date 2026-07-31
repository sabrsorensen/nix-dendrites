{ ... }:
{
  flake.modules.nixos.samba =
    args@{ config, lib, ... }:
    let
      cfg = config.my.samba;
    in
    {
      options.my.samba.settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional Samba settings merged on top of the shared defaults.";
      };
      config = lib.mkIf config.my.host.services.samba (import ./_content.nix (args // { inherit cfg; }));
    };
}
