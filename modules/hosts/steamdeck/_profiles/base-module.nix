{
  descriptor,
  host,
}:
{
  bootMode,
  lifecycle,
  extraImports ? [ ],
  extraConfig ? { },
}:
{
  imports = extraImports ++ [ extraConfig ];

  networking.hostName = descriptor.hostName;
  my.host = descriptor.config // {
    lifecycle.mode = lifecycle;
  };

  my.platform.steamdeck = {
    enable = true;
    inherit bootMode lifecycle;
  };
}
