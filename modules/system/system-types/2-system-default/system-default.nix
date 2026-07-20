{
  inputs,
  ...
}:
{
  # import all essential nix-tools which are used in all modules of a specific class

  flake.modules.nixos.system-default = {
    imports =
      with inputs.self.modules.nixos;
      [
        system-minimal
        home-manager
        ssh
        syncthing
        firmware
        cli-tools
        nix-index
        nix-ld
        secrets-base
        secrets-context
        system-secrets
        locale
        audio
        appimage
        kde
        noson
        printing
        plymouth
        docker
        podman
        wayland
        xserver
        zsa
        cross-compile
        bluetooth
        deskflow
        threedprinter
        minecraft
        steam
        nvidia
        wine
      ]
      ++ (with inputs.self.modules.generic; [
        pkgs-by-name
      ]);
  };

  flake.modules.homeManager.system-default = {
    imports =
      with inputs.self.modules.homeManager;
      [
        system-minimal
        noson
        secrets-base
        secrets-context
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}
