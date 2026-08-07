{ lib, ... }:
{
  packageFlavor = lib.mkOption {
    type = lib.types.enum [
      "vscode"
      "vscodium"
    ];
    default = "vscodium";
    description = "Editor package family used for managed profiles.";
  };
  installLocalDotnetSdk = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Install the local .NET SDK used by managed editor profiles.";
  };
  profiles = {
    higiLlp = lib.mkEnableOption "the Higi LLP editor profile";
    python = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "the Python editor profile";
    };
    stm32 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "the STM32 editor profile";
    };
  };
  higi.runCodexInWsl = lib.mkEnableOption "running Codex in WSL from the Higi LLP profile";
}
