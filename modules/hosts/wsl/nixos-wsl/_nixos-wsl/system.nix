{
  inputs,
  ...
}:
{
  imports =
    (with inputs.self.modules.nixos; [
      wsl-base
      system-cli
    ])
    ++ [ "${inputs.nix-work-secrets}/modules/system-secrets-private.nix" ];

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
}
