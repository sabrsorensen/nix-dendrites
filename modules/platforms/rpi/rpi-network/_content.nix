{
  config,
  network,
  ...
}:
{
  networking = {
    useDHCP = false;
    defaultGateway = {
      address = network.gateway;
      interface = "end0";
    };
    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = config.my.host.address;
          prefixLength = 24;
        }
      ];
    };
  };
}
