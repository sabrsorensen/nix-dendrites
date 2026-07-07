{
  inputs,
  lib,
}:
let
  serviceRoleUnits = {
    "blocky-dns" = [
      "blocky"
      "coredns"
    ];
    "dhcp-primary" = [ "dhcp-coredns-kea" ];
    "dhcp-standby" = [ "dhcp-failover.timer" ];
  };
  expandServiceRoles =
    roles: lib.unique (lib.concatLists (map (role: serviceRoleUnits.${role} or [ ]) roles));
in
{
  inherit serviceRoleUnits;
  inherit expandServiceRoles;

  mkHomeManagerInventory =
    inventory:
    lib.mapAttrs (
      _name: host:
      host
      // lib.optionalAttrs (host ? deploy && host.deploy ? secure) {
        deploy = host.deploy // {
          secure =
            let
              secureCfg = host.deploy.secure;
              peerCfg = inventory.${secureCfg.peerName} or { };
            in
            secureCfg
            // {
              peerServices = expandServiceRoles (peerCfg.serviceRoles or [ ]);
              targetServices = expandServiceRoles (host.serviceRoles or [ ]);
            };
        };
      }
    ) inventory;
}
