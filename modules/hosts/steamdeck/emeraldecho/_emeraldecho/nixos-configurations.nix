{ inputs, lib }:
lib.mkMerge [
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEcho")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoDualBoot")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoSingleBoot")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoBootstrap")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoDualBootBootstrap")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoSingleBootBootstrap")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoInstaller")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoDualBootInstaller")
  (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoSingleBootInstaller")
]
