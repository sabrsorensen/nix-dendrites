{
  self,
  lib,
  ...
}:
let
  domain = lib.removeSuffix "\n" (builtins.readFile "${self.inputs.nix-secrets}/domain.txt");
  network = builtins.fromJSON (builtins.readFile "${self.inputs.nix-secrets}/network.json");
in
{
  flake.modules.generic.systemConstants =
    { lib, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
      };

      config.systemConstants = {
        inherit domain network;
        adminEmail = "admin@${domain}";
      };
    };
}
