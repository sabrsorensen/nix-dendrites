{ inputs, ... }:
let
  genericPackages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      hasLocalFlake = config.my.host.deploy.localFlakePath != null;
      hasLocalGuiFlake = hasLocalFlake && config.my.host.features.gui;
      qtPluginPath = lib.concatStringsSep ":" [
        "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"
        "${pkgs.qt5.qtwayland}/${pkgs.qt5.qtbase.qtPluginPrefix}"
      ];
      qtQmlPath = lib.concatStringsSep ":" [
        "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtQmlPrefix}"
        "${pkgs.qt5.qtwayland}/${pkgs.qt5.qtbase.qtQmlPrefix}"
      ];
      leasesEditorPython = pkgs.python3.withPackages (
        pythonPkgs: with pythonPkgs; [
          pyqt5
        ]
      );
      leasesEditor = pkgs.writeShellApplication {
        name = "leases_editor.py";
        runtimeInputs = [
          leasesEditorPython
          pkgs.qt5.qtbase
          pkgs.qt5.qtwayland
        ];
        text = ''
          export QT_PLUGIN_PATH=${lib.escapeShellArg qtPluginPath}
          export QML2_IMPORT_PATH=${lib.escapeShellArg qtQmlPath}
          exec ${leasesEditorPython}/bin/python ${../../services/dhcp-coredns/leases_editor.py} "$@"
        '';
      };
      localFlakeToolPackages =
        lib.optionals hasLocalFlake [
          pkgs.just
          inputs.self.formatter.${system}
          inputs.self.packages.${system}.write-flake
          inputs.self.packages.${system}.write-inputs
          inputs.self.packages.${system}.write-lock
        ]
        ++ lib.optionals hasLocalGuiFlake [ leasesEditor ];
    in
    {
      environment.systemPackages =
        with pkgs;
        [
          git
          tmux
          home-manager
          cowsay
        ]
        ++ localFlakeToolPackages;
    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [
      genericPackages
    ];
  };
}
