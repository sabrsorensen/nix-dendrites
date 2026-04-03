{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      x86Checks = {
        atlasuponraiden = inputs.self.nixosConfigurations.AtlasUponRaiden.config.system.build.toplevel;
        kamino = inputs.self.nixosConfigurations.Kamino.config.system.build.toplevel;
        zaphodbeeblebrox = inputs.self.nixosConfigurations.ZaphodBeeblebrox.config.system.build.toplevel;
        "nixos-wsl" = inputs.self.nixosConfigurations.NixOS-WSL.config.system.build.toplevel;
        emeraldecho = inputs.self.nixosConfigurations.EmeraldEcho.config.system.build.toplevel;
        "emeraldecho-bootstrap" =
          inputs.self.nixosConfigurations.EmeraldEchoBootstrap.config.system.build.toplevel;
        "emeraldecho-installer" =
          inputs.self.nixosConfigurations.EmeraldEchoInstaller.config.system.build.isoImage;
        "emeraldecho-dualboot" =
          inputs.self.nixosConfigurations.EmeraldEchoDualBoot.config.system.build.toplevel;
        "emeraldecho-dualboot-bootstrap" =
          inputs.self.nixosConfigurations.EmeraldEchoDualBootBootstrap.config.system.build.toplevel;
        "emeraldecho-dualboot-installer" =
          inputs.self.nixosConfigurations.EmeraldEchoDualBootInstaller.config.system.build.isoImage;
        "home-deck-emeraldecho" = inputs.self.homeConfigurations."deck@EmeraldEcho".activationPackage;
      };

      armChecks = {
        coruscant = inputs.self.nixosConfigurations.Coruscant.config.system.build.toplevel;
        ferrix = inputs.self.nixosConfigurations.Ferrix.config.system.build.toplevel;
        naboo = inputs.self.nixosConfigurations.Naboo.config.system.build.toplevel;
        "naboo-image" = inputs.self.nixosConfigurations.NabooImage.config.system.build.sdImage;
        nevarro = inputs.self.nixosConfigurations.Nevarro.config.system.build.toplevel;
        "nevarro-image" = inputs.self.nixosConfigurations.NevarroImage.config.system.build.sdImage;
        nixpi = inputs.self.nixosConfigurations.NixPi.config.system.build.toplevel;
        "nixpi-image" = inputs.self.nixosConfigurations.NixPiImage.config.system.build.sdImage;
      };

      steamDeckPackages = {
        emeraldecho = inputs.self.nixosConfigurations.EmeraldEcho.config.system.build.toplevel;
        "emeraldecho-bootstrap" =
          inputs.self.nixosConfigurations.EmeraldEchoBootstrap.config.system.build.toplevel;
        "emeraldecho-installer" =
          inputs.self.nixosConfigurations.EmeraldEchoInstaller.config.system.build.isoImage;
        "emeraldecho-dualboot" =
          inputs.self.nixosConfigurations.EmeraldEchoDualBoot.config.system.build.toplevel;
        "emeraldecho-dualboot-bootstrap" =
          inputs.self.nixosConfigurations.EmeraldEchoDualBootBootstrap.config.system.build.toplevel;
        "emeraldecho-dualboot-installer" =
          inputs.self.nixosConfigurations.EmeraldEchoDualBootInstaller.config.system.build.isoImage;
        "emeraldecho-singleboot" =
          inputs.self.nixosConfigurations.EmeraldEchoSingleBoot.config.system.build.toplevel;
        "emeraldecho-singleboot-bootstrap" =
          inputs.self.nixosConfigurations.EmeraldEchoSingleBootBootstrap.config.system.build.toplevel;
        "emeraldecho-singleboot-installer" =
          inputs.self.nixosConfigurations.EmeraldEchoSingleBootInstaller.config.system.build.isoImage;
        "home-deck-emeraldecho" = inputs.self.homeConfigurations."deck@EmeraldEcho".activationPackage;
      };
    in
    {
      checks =
        lib.optionalAttrs (system == "x86_64-linux") x86Checks
        // lib.optionalAttrs (system == "aarch64-linux") armChecks;

      packages = lib.optionalAttrs (system == "x86_64-linux") steamDeckPackages;
    };
}
