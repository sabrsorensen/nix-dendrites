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
in
{
  inherit serviceRoleUnits;

  expandServiceRoles =
    roles:
    lib.unique (lib.concatLists (map (role: serviceRoleUnits.${role} or [ ]) roles));

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
              peerServices = inputs.self.lib.shared.expandServiceRoles (peerCfg.serviceRoles or [ ]);
              targetServices = inputs.self.lib.shared.expandServiceRoles (host.serviceRoles or [ ]);
            };
        };
      }
    ) inventory;
}
