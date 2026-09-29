{ ... }:
{
  networking.firewall = {
    # 1400-1410: speaker event callbacks (noson, and SoCo's listener counting
    # up from 1400) plus Sonolin's media server on 1405, which the speakers
    # fetch local music and streamed desktop audio from.
    allowedTCPPortRanges = [
      {
        from = 1400;
        to = 1410;
      }
    ];
    allowedTCPPorts = [ 3400 ];
  };
}
