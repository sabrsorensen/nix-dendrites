{ network }:
{
  networking.hostName = "Ferrix";
  my.host = {
    name = "Ferrix";
    address = network.ferrix;
    formFactor = "server";
    platform = "rpi";
    home.enable = true;
  };
}
