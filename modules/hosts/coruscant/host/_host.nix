{ network }:
{ config, ... }:
{
  networking.hostName = "Coruscant";
  my.host = {
    name = "Coruscant";
    address = network.coruscant;
    formFactor = "server";
    platform = "rpi";
    home.enable = true;
  };
  my.localDns.records = [ { hostname = "homeassistant"; } ];
}
