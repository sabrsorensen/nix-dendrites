{ inputs, lib, ... }:
let
  publisherOutputs = [
    "atlasuponraiden"
    "coruscant"
    "emeraldecho"
    "ferrix"
    "kamino"
    "nixpi"
    "zaphodbeeblebrox"
  ];
in
{
  # DNS authorities consume publications from ordinary hosts. Naboo and Nevarro
  # are deliberately excluded: they are the consumers, avoiding self-reference
  # while their own infrastructure records remain explicit in the DNS module.
  flake.lib = {
    mkIfPersistence =
      config: settings:
      if config ? home then
        if config.home ? persistence then settings else { }
      else if config.environment ? persistence then
        settings
      else
        { };
    localDns.publishedRecords = builtins.concatLists (
      map (
        output: inputs.self.nixosConfigurations.${output}.config.my.localDns.publishedRecords
      ) publisherOutputs
    );
  };
}
