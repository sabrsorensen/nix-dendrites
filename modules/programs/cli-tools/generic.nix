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
      leasesEditorPython = pkgs.python3.withPackages (
        pythonPkgs: with pythonPkgs; [
          pyqt5
        ]
      );
      leasesEditor = pkgs.writeShellApplication {
        name = "leases_editor.py";
        runtimeInputs = [ leasesEditorPython ];
        text = ''
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
