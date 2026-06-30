{
  flake.modules.nixos.minecraft-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      geyserVersion = "2.10.1";
      geyserBuild = "1164";
      floodgateVersion = "2.2.5";
      floodgateBuild = "132";

      geyserSpigot = pkgs.fetchurl {
        # Pin plugin jars in the store so the container doesn't fetch mutable
        # "latest" artifacts during startup.
        url = "https://download.geysermc.org/v2/projects/geyser/versions/${geyserVersion}/builds/${geyserBuild}/downloads/spigot";
        hash = "sha256-mqPa3gkLGAI+zCFXiz9fiyTq0eQFVPvmdgjT1zkob3w=";
      };
      floodgateSpigot = pkgs.fetchurl {
        url = "https://download.geysermc.org/v2/projects/floodgate/versions/${floodgateVersion}/builds/${floodgateBuild}/downloads/spigot";
        hash = "sha256-ZR31ephvY1BqEcLyxrJxR+3snFkJT6ffzCGhMdqKEDA=";
      };
      paperPlugins = pkgs.runCommandLocal "minecraft-paper-plugins" { } ''
        mkdir -p "$out"
        cp ${geyserSpigot} "$out/Geyser-Spigot.jar"
        cp ${floodgateSpigot} "$out/floodgate-spigot.jar"
      '';
    in
    {
      options.my.services.minecraft.enable = lib.mkEnableOption "Minecraft server stack";

      config = lib.mkIf config.my.services.minecraft.enable {
        virtualisation.oci-containers.containers."mc-bc" = {
          image = "pugmatt/bedrock-connect";
          volumes = [
            "/opt/minecraft/bedrock-connect/config.yml:/docker/brc/config.yml:rw"
            "/opt/minecraft/bedrock-connect/custom_servers.json:/app/custom_servers.json:rw"
            "/opt/minecraft/bedrock-connect/players:/app/players:rw"
          ];
          ports = [
            "19132:19132/udp"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=mc-bc"
          ];
        };

        virtualisation.oci-containers.containers."mc-java" = {
          image = "itzg/minecraft-server";
          environment = {
            "EULA" = "TRUE";
            "SERVER_NAME" = "Hendoboom Zone";
            "TYPE" = "PAPER";
            "TZ" = "America/Boise";
            "VERSION" = "1.21.8";
          };
          volumes = [
            "/opt/minecraft/minecraft-server/data:/data:rw"
            "${paperPlugins}:/plugins:ro"
          ];
          ports = [
            "25565:25565/tcp"
            "19133:19132/udp"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=mc-java"
          ];
        };
      };
    };
}
