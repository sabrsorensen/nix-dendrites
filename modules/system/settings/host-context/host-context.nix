{
  config,
  lib,
  ...
}:
let
  hostContextOptions = import ../../../lib/_host-context-options.nix { inherit lib; };
in
{
  options.my.host = hostContextOptions.mkSharedHostOptions {
    nameDefault = config.networking.hostName;
    nameDescription = "Canonical host name for shared module behavior.";
    domainDefault =
      if config ? systemConstants && config.systemConstants ? domain then config.systemConstants.domain else null;
    domainDescription = "Local domain associated with this host.";
    includeAddress = true;
    includeDeployEnableRemoteUser = true;
    includeDeployLocalFlakePath = true;
    includeNixBuildMachines = true;
  };

  options.my.localDns = {
    records = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.str;
              description = "Short hostname published into the local DNS zone.";
            };

            ip = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Explicit IP override for this record. Defaults to my.host.address.";
            };
          };
        }
      );
      default = [ ];
      description = "Local DNS records owned by this host or its services.";
    };

    publishedRecords = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.str;
            };

            ip = lib.mkOption {
              type = lib.types.str;
            };
          };
        }
      );
      default = [ ];
      description = "Materialized local DNS records with concrete IP addresses.";
    };
  };

  config = {
    my.localDns.publishedRecords = map (
      record:
      record
      // {
        ip =
          if record.ip != null then
            record.ip
          else
            config.my.host.address;
      }
    ) config.my.localDns.records;
  };
}
