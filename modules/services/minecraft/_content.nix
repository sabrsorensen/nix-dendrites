{ pkgs, ... }:
let
  geyserSpigot = pkgs.fetchurl {
    url = "https://download.geysermc.org/v2/projects/geyser/versions/2.10.1/builds/1164/downloads/spigot";
    hash = "sha256-mqPa3gkLGAI+zCFXiz9fiyTq0eQFVPvmdgjT1zkob3w=";
  };
  floodgateSpigot = pkgs.fetchurl {
    url = "https://download.geysermc.org/v2/projects/floodgate/versions/2.2.5/builds/132/downloads/spigot";
    hash = "sha256-ZR31ephvY1BqEcLyxrJxR+3snFkJT6ffzCGhMdqKEDA=";
  };
  paperPlugins = pkgs.runCommandLocal "minecraft-paper-plugins" { } ''
    mkdir -p "$out"
    cp ${geyserSpigot} "$out/Geyser-Spigot.jar"
    cp ${floodgateSpigot} "$out/floodgate-spigot.jar"
  '';
in
{
  virtualisation.oci-containers.containers = {
    mc-bc = {
      image = "pugmatt/bedrock-connect";
      volumes = [
        "/opt/minecraft/bedrock-connect/config.yml:/docker/brc/config.yml:rw"
        "/opt/minecraft/bedrock-connect/custom_servers.json:/app/custom_servers.json:rw"
        "/opt/minecraft/bedrock-connect/players:/app/players:rw"
      ];
      ports = [ "19132:19132/udp" ];
      log-driver = "journald";
      extraOptions = [ "--network-alias=mc-bc" ];
    };
    mc-java = {
      image = "itzg/minecraft-server";
      environment = {
        EULA = "TRUE";
        SERVER_NAME = "Hendoboom Zone";
        TYPE = "PAPER";
        TZ = "America/Boise";
        VERSION = "1.21.8";
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
      extraOptions = [ "--network-alias=mc-java" ];
    };
  };
}
