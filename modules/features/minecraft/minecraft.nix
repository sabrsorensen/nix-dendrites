{ inputs, ... }:
{
  # Upstream only builds x86_64-linux and runs the GDK Bedrock client under
  # steam-run, so the package is only added on x86_64 hosts.
  flake-file.inputs.bedrock-on-linux = {
    url = "github:Wyze3306/BedrockOnLinux";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.minecraft-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.minecraft = lib.mkEnableOption "Minecraft tooling";
      config = lib.mkIf config.my.host.features.minecraft (
        import ./_minecraft.nix { inherit inputs lib pkgs; }
      );
    };
}
