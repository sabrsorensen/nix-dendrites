{
  inputs,
  network,
  publisherOutputs,
}:
{
  mkIfPersistence =
    config: settings:
    if config ? home then
      if config.home ? persistence then settings else { }
    else if config.environment ? persistence then
      settings
    else
      { };
  localDns = {
    publishedRecords = builtins.concatLists (
      map (
        output: inputs.self.nixosConfigurations.${output}.config.my.localDns.publishedRecords
      ) publisherOutputs
    );
    staticRecords = [
      {
        hostname = "ns1";
        ip = network.nevarro;
      }
      {
        hostname = "ns2";
        ip = network.naboo;
      }
      {
        hostname = "home-gw";
        ip = network.gateway;
      }
    ]
    ++ inputs.self.lib.localDns.publishedRecords;
  };
}
