{ inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  port = 7877;
  hubAddress = network.atlasuponraiden;
  hubUrl = "http://${hubAddress}:${toString port}";
  # network.json's subnet_mask is 255.255.254.0. The hub speaks plain HTTP and
  # any token can search every transcript, so it is never reachable off-LAN.
  lanCidr = "192.168.0.0/23";

  # One hub token per satellite, stored as crispy_recall/<name> in
  # nix-secrets/secrets.yaml (64 hex chars, e.g. `openssl rand -hex 32`). The
  # hub derives its hub-tokens.json from these same secrets, so this list must
  # match the hosts where my.host.features.recall ends up true (by default,
  # every Claude host).
  satellites = [
    "kamino"
    "pabu"
    "zaphodbeeblebrox"
  ];
  secretsFile = "${inputs.nix-secrets}/secrets.yaml";
  tokenKey = host: "crispy_recall/${host}";

  mkPackages = pkgs: {
    recall = pkgs.callPackage ./_package.nix { crispy-recall-src = inputs.crispy-recall; };
    llama = pkgs.callPackage ./_llama-cpp.nix { };
    # The embedding model `recall install` would otherwise download into
    # ~/.recall/models; only the hub embeds.
    model = pkgs.fetchurl {
      url = "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf";
      hash = "sha256-PiQ0IWSz2UmRupaS/cDdCOP9c2Lgqsw5appcVKVEw7c=";
    };
  };

  homeModule = import ./_satellite-home.nix {
    inherit
      hubUrl
      mkPackages
      secretsFile
      tokenKey
      ;
  };
in
{
  # Pinned to a release tag: satellites upload raw transcripts to the hub, so
  # every bump deserves a read of the changelog (and a hub DB backup).
  flake-file.inputs.crispy-recall = {
    url = "github:TheSylvester/crispy-recall/v0.4.0";
    flake = false;
  };

  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.crispy-recall = homeModule;

  flake.modules.nixos.crispy-recall =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.recall =
        lib.mkEnableOption "crispy-recall satellite (Claude Code transcripts pushed to the recall hub)";
      options.my.host.services.recallHub =
        lib.mkEnableOption "crispy-recall hub (transcript index for every satellite)";

      config = lib.mkMerge [
        { my.host.features.recall = lib.mkDefault config.my.host.features.claude; }
        (lib.mkIf config.my.host.services.recallHub (
          import ./_hub.nix (
            args
            // {
              inherit
                hubAddress
                lanCidr
                mkPackages
                port
                satellites
                secretsFile
                tokenKey
                ;
            }
          )
        ))
      ];
    };
}
