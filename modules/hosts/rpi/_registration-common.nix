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
    if descriptor ? outputs && descriptor.outputs ? bootstrap then
      descriptor.outputs.bootstrap
    else
      descriptor.bootstrap or null;

  descriptorImage =
    {
      descriptor,
    }:
    if descriptor ? outputs && descriptor.outputs ? image && descriptor.outputs.image.enable then
      descriptor.outputs.image
    else if descriptor ? image then
      descriptor.image // { enable = true; }
    else
      {
        enable = false;
        name = null;
      };

  descriptorNetworkMode =
    {
      descriptor,
    }:
    if descriptor.network ? mode then
      descriptor.network.mode
    else if descriptor.network ? dhcp && descriptor.network.dhcp then
      "dhcp"
    else if descriptor ? kind && descriptor.kind == "dhcp" then
      "dhcp"
    else
      "static";

  descriptorIsServiceHost =
    {
      descriptor,
    }:
    descriptor.deploy.method or null == "secure"
    || (descriptor.services.roles or [ ]) != [ ]
    || (descriptor ? kind && descriptor.kind == "service");

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
            primaryInteractiveUser =
              if descriptor ? users && descriptor.users ? primary then
                descriptor.users.primary.name
              else
                descriptor.user.name;
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
        primaryInteractiveUser =
          if descriptor ? users && descriptor.users ? primary then
            descriptor.users.primary.name
          else
            descriptor.user.name;
        formFactor = "server";
        roles = {
          server = true;
          rpi = true;
          serviceHost = true;
        };
      };
    };
}
