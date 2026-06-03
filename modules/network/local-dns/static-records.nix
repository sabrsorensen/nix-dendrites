{
  inputs,
  lib,
  ...
}:
let
  hostInventory = inputs.self.lib.hostInventory or { };
  network = inputs.self.lib.site.network;
  domain = inputs.self.lib.site.domain;
  defaultDnsConfigurationsFor =
    host:
    map (descriptor: descriptor.configuration) (
      builtins.filter (
        descriptor:
        descriptor.kind == "nixos"
        && descriptor.collection == "checks"
        &&
          descriptor.buildAttrPath == [
            "config"
            "system"
            "build"
            "toplevel"
          ]
      ) (host.outputs or [ ])
    );
  inventoryNixosConfigurations = lib.unique (
    builtins.concatMap (
      host: if host ? dnsConfigurations then host.dnsConfigurations else defaultDnsConfigurationsFor host
    ) (builtins.attrValues hostInventory)
  );
  infraRecords = [
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
  ];
in
{
  flake.lib.localDns = {
    inherit domain;

    inventoryNixosConfigurations = inventoryNixosConfigurations;

    publishedRecordsFromConfigurations =
      configurations:
      builtins.concatLists (
        map (
          configuration:
          inputs.self.nixosConfigurations.${configuration}.config.my.localDns.publishedRecords or [ ]
        ) configurations
      );

    inventoryPublishedRecords = inputs.self.lib.localDns.publishedRecordsFromConfigurations inventoryNixosConfigurations;

    staticRecords = infraRecords ++ inputs.self.lib.localDns.inventoryPublishedRecords;

    secureDeployProbeDomains = map (hostname: "${hostname}.${domain}") [
      "naboo"
      "nevarro"
      "atlasuponraiden"
    ];
  };
}
