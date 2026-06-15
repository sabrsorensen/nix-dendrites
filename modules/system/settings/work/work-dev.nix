{
  inputs,
  ...
}:
{
  flake.modules.nixos."work-dev" =
    { ... }:
    {
      imports =
        (with inputs.self.modules.nixos; [
          deploy-defaults
          system-cli
        ])
        ++ [ "${inputs.nix-work-secrets}/modules/system-secrets-private.nix" ];

      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "dotnet-sdk-6.0.428"
          "dotnet-sdk-7.0.410"
        ];
      };

      programs.fish.enable = true;
    };
}
