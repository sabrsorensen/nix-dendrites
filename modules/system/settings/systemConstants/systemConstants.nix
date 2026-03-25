{
  self,
  ...
}:
{
  flake.modules.generic.systemConstants =
    { lib, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
      };

      config.systemConstants = {
        adminEmail = "admin@${lib.readFile "${self.inputs.nix-secrets}/domain.txt"}";
      };
    };
}
