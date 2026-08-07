{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  perSystem =
    { pkgs, lib, ... }:
    let
      qtPluginPath = lib.concatStringsSep ":" [
        "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"
        "${pkgs.qt5.qtwayland}/${pkgs.qt5.qtbase.qtPluginPrefix}"
      ];
      qtQmlPath = lib.concatStringsSep ":" [
        "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtQmlPrefix}"
        "${pkgs.qt5.qtwayland}/${pkgs.qt5.qtbase.qtQmlPrefix}"
      ];
      leasesEditorPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pyqt5 ]);
    in
    {
      packages.leases-editor = pkgs.writeShellApplication {
        name = "leases_editor.py";
        runtimeInputs = [
          leasesEditorPython
          pkgs.qt5.qtbase
          pkgs.qt5.qtwayland
        ];
        text = ''
          export QT_PLUGIN_PATH=${lib.escapeShellArg qtPluginPath}
          export QML2_IMPORT_PATH=${lib.escapeShellArg qtQmlPath}
          exec ${leasesEditorPython}/bin/python ${./assets/scripts/leases_editor.py} "$@"
        '';
      };
    };

  flake.modules.nixos.dhcp-coredns =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.dhcpCoredns;
      enabled = config.my.host.services.dhcpCoredns;
      # Include records published by enabled hosts and services as well as the
      # fixed bootstrap records. This keeps the generated CoreDNS zone aligned
      # with the local-DNS publication interface instead of requiring a second
      # hand-maintained record list here.
      zoneStaticRecords =
        cfg.staticRecords ++ inputs.self.lib.localDns.staticRecords ++ config.my.localDns.publishedRecords;
      networkConfig = network;
      localDomain = domain;
      collectLeases = ./assets/scripts/collect_leases.py;
      renderZone = ./assets/scripts/render_zone.py;
      leasesFile = "${inputs.nix-secrets}/leases.json";
    in
    {
      options.my.dhcpCoredns = {
        enable = lib.mkEnableOption "DHCP + CoreDNS local DNS stack";

        interface = lib.mkOption {
          type = lib.types.str;
          default = "end0";
        };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/dhcp-coredns";
        };

        dnsListen = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0:1053";
        };

        upstreamServers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        staticRecords = lib.mkOption {
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
          description = "Static DNS records rendered into the local CoreDNS zone.";
        };

        startKeaOnBoot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the runtime-generated Kea DHCP service should start automatically at boot.";
        };

        localDomainApexIp = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "If set, resolve the root of the local domain to this local IP in CoreDNS.";
        };
      };

      config = lib.mkIf enabled (
        import ./_dhcp-coredns.nix (
          args
          // {
            inherit
              cfg
              collectLeases
              leasesFile
              localDomain
              networkConfig
              renderZone
              zoneStaticRecords
              ;
          }
        )
      );
    };
}
