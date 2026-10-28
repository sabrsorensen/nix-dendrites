{
  config,
  lib,
  pkgs,
  ...
}:
let
  stm32cubeide = pkgs.callPackage ./_stm32cubeide/package.nix {
    swt = pkgs.callPackage ./_stm32cubeide/swt.nix { };
  };
  ideSupported = lib.meta.availableOn pkgs.stdenv.hostPlatform stm32cubeide;
in
{
  options.my.features.stm32 = lib.mkEnableOption "STM32 development tools";

  # The command-line toolchain is ported from the standalone ~/src/stm32
  # devShell; STM32CubeIDE rides alongside it rather than owning it.
  config = lib.mkIf config.my.features.stm32 {
    assertions = [
      {
        assertion = ideSupported;
        message = "my.features.stm32 (STM32CubeIDE) only supports ${lib.concatStringsSep " / " stm32cubeide.meta.platforms}; ST ships no build for ${pkgs.stdenv.hostPlatform.system}.";
      }
    ];

    home.packages =
      with pkgs;
      [
        clang-tools
        cmake
        gcc-arm-embedded
        ninja
        openocd
        probe-rs-tools
        stm32cubemx
        stm32flash
        stm32loader
        stlink
      ]
      # The optional keeps the meta.platforms refusal from masking the
      # assertion above.
      ++ lib.optional ideSupported stm32cubeide;
  };
}
