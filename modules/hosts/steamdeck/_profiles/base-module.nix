{
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

  networking.hostName = host.primaryHostName;
  my.host = host.context;

  my.platform.steamdeck = {
    enable = true;
    inherit bootMode lifecycle;
  };
}
