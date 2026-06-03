{ lib, ... }:
let
  hostContextOptions = import ../../lib/_host-context-options.nix { inherit lib; };
in
{
  options.my.host = hostContextOptions.mkSharedHostOptions {
    nameDefault = "standalone";
    nameDescription = "Canonical host name for shared Home Manager behavior.";
    domainDescription = "Local domain associated with this host context.";
  };
}
