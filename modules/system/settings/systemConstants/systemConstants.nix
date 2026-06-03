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
        inherit (self.lib.site) domain network atlas;
        adminEmail = "admin@${self.lib.site.domain}";
      };
    };
}
