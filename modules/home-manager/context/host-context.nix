{
  inputs,
  lib,
  ...
}:
let
  hostContextOptions = inputs.self.lib.shared.hostContextOptions;
in
{
  flake.modules.homeManager.host-context =
    {
      config,
      ...
    }:
    {
      options.my.host = hostContextOptions.mkSharedHostOptions {
        nameDefault = "standalone";
        nameDescription = "Canonical host name for shared Home Manager behavior.";
        domainDescription = "Local domain associated with this host context.";
        includeDeployLocalFlakePath = true;
      };

      config.my.host.is = {
        workstation = lib.mkDefault (config.my.host.roles.workstation || config.my.host.features.gui);
        server = lib.mkDefault (config.my.host.roles.server || config.my.host.formFactor == "server");
        builder = lib.mkDefault config.my.host.roles.builder;
        desktop = lib.mkDefault (config.my.host.formFactor == "desktop");
        laptop = lib.mkDefault (config.my.host.formFactor == "laptop");
        handheld = lib.mkDefault (config.my.host.formFactor == "handheld");
        steamdeck = lib.mkDefault (
          config.my.host.roles.steamdeck || config.my.host.formFactor == "handheld"
        );
        rpi = lib.mkDefault config.my.host.roles.rpi;
        wsl = lib.mkDefault config.my.host.roles.wsl;
        headless = lib.mkDefault (!config.my.host.features.gui);
      };
    };
}
