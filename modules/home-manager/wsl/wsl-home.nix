{
  inputs,
  ...
}:
{
  flake.modules.homeManager."wsl-home" =
    {
      lib,
      pkgs,
      ...
    }:
    let
      dotnetCombined = pkgs.dotnetCorePackages.combinePackages [
        pkgs.dotnetCorePackages.sdk_6_0-bin
        pkgs.dotnetCorePackages.sdk_7_0-bin
        pkgs.dotnetCorePackages.sdk_8_0-bin
        pkgs.dotnetCorePackages.sdk_9_0-bin
        pkgs.dotnetCorePackages.sdk_10_0-bin
        pkgs.dotnetCorePackages.sdk_11_0-bin
      ];
    in
    {
      imports =
        (with inputs.self.modules.homeManager; [
          home
          sam-git
          sam-work-secrets
          vscode
          vscode-wsl
          mcp
          mcp-work
          codex
          nuget
        ])
        ++ [
          "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix"
        ];

      home.username = lib.mkDefault "sam";
      home.homeDirectory = lib.mkDefault "/home/sam";

      home.packages =
        with pkgs;
        lib.filter (pkg: pkg != null) [
          git
          dotnetCombined
          (if pkgs ? azure-cli then azure-cli else null)
          (if pkgs ? pulumi then pulumi else null)
          (if pkgs ? spec-kit then spec-kit else null)
          (
            if pkgs ? uv then
              uv
            else if pkgs ? unstable && pkgs.unstable ? uv then
              pkgs.unstable.uv
            else
              null
          )
          (if pkgs ? nodejs_25 then nodejs_25 else null)
        ];
    };
}
