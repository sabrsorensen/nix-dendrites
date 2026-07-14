{
  lib,
}:
rec {
  descriptorHostName =
    {
      descriptor,
      fallbackToName ? false,
    }:
    if descriptor ? hostName then
      descriptor.hostName
    else if descriptor ? network && descriptor.network ? hostName then
      descriptor.network.hostName
    else if fallbackToName then
      descriptor.name
    else
      throw "RPi descriptor is missing network.hostName";

  descriptorBootstrap =
    {
      descriptor,
    }:
    descriptor.outputs.bootstrap;

  descriptorImage =
    {
      descriptor,
    }:
    if descriptor.outputs.image.enable then
      descriptor.outputs.image
    else
      {
        enable = false;
        name = null;
      };

  descriptorNetworkMode =
    {
      descriptor,
    }:
    descriptor.network.mode;

  descriptorIsServiceHost =
    {
      descriptor,
    }:
    descriptor.deploy.method or null == "secure" || descriptor.services.roles != [ ];

  mergeHostFacts =
    {
      generated,
      descriptor,
    }:
    lib.recursiveUpdate generated (descriptor.my.host or { });

  mkBootstrapHostFacts =
    {
      descriptor,
    }:
    mergeHostFacts {
      descriptor = descriptor;
      generated = {
        lifecycle.mode = "bootstrap";
        bootstrap.finalConfigName =
          (descriptorBootstrap {
            inherit descriptor;
          }).finalConfigName or descriptor.name;
        roles.rpi = true;
      }
      // lib.optionalAttrs (descriptor.network.address != null) {
        address = descriptor.network.address;
      }
      //
        lib.optionalAttrs
          (descriptorIsServiceHost {
            inherit descriptor;
          })
          {
            primaryInteractiveUser = descriptor.users.primary.name;
            formFactor = "server";
            roles = {
              server = true;
              rpi = true;
              serviceHost = true;
            };
          };
    };

  mkStaticHostFacts =
    {
      descriptor,
    }:
    mergeHostFacts {
      descriptor = descriptor;
      generated = {
        address = descriptor.network.address;
        roles.rpi = true;
      };
    };

  mkDhcpHostFacts =
    {
      descriptor,
    }:
    mergeHostFacts {
      descriptor = descriptor;
      generated = {
        roles.rpi = true;
      };
    };

  mkServiceHostFacts =
    {
      descriptor,
    }:
    mergeHostFacts {
      descriptor = descriptor;
      generated = {
        primaryInteractiveUser = descriptor.users.primary.name;
        formFactor = "server";
        roles = {
          server = true;
          rpi = true;
          serviceHost = true;
        };
      };
    };
}
