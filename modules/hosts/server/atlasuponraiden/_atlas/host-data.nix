{ inputs, ... }:
{
  user = {
    name = "sam";
  };

  home.imports = import ./home-imports.nix { inherit inputs; };
  config = import ./config.nix;
  localDnsRecords = import ./local-dns-records.nix;
  inventory = import ./inventory.nix { inherit inputs; };
}
