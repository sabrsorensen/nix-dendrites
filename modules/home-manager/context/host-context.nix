{
  inputs,
  lib,
  ...
}:
let
  hostContextOptions = inputs.self.lib.shared.hostContextOptions;
in
{
  flake.modules.homeManager.host-context = {
    options.my.host = hostContextOptions.mkSharedHostOptions {
      nameDefault = "standalone";
      nameDescription = "Canonical host name for shared Home Manager behavior.";
      domainDescription = "Local domain associated with this host context.";
      includeDeployLocalFlakePath = true;
    };
  };
}
