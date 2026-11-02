{ config, pkgs, ... }:
let
  # Bedrock's NetherNet transport needs TCP (signaling) and UDP (WebRTC) on the
  # same port. Geyser and BedrockConnect both listen on 19132 inside their
  # containers; Geyser is published on host port 19133.
  geyserPort = 19133;

  # Geyser's built-in signaling hands clients its own addresses as WebRTC
  # candidates. Inside the container those are the podman bridge IP and a
  # STUN-discovered public address, neither of which a LAN client can reach,
  # so advertise the host's LAN address and published port instead.
  # PATCH_DEFINITIONS pointing at a directory expects one bare {file, ops}
  # definition per file; the {patches = [...]} patch-set wrapper is rejected.
  geyserPatches = pkgs.writeTextDir "geyser.json" (
    builtins.toJSON {
      file = "/data/plugins/Geyser-Spigot/config.yml";
      ops = [
        {
          "$set" = {
            path = "$.bedrock.signaling['advertise-addresses']";
            value = [ "${config.my.host.address}:${toString geyserPort}" ];
          };
        }
      ];
    }
  );

  javaServerName = "Hendoboom Zone";
  javaPort = 25565;
in
{
  networking.firewall = {
    allowedTCPPorts = [
      19132
      geyserPort
      javaPort
    ];
    allowedUDPPorts = [
      19132
      geyserPort
    ];
  };
  virtualisation.oci-containers.containers = {
    mc-bc = {
      image = "pugmatt/bedrock-connect";
      pull = "newer";
      volumes = [
        "/opt/minecraft/bedrock-connect/config.yml:/docker/brc/config.yml:rw"
        "/opt/minecraft/bedrock-connect/custom_servers.json:/app/custom_servers.json:rw"
        "/opt/minecraft/bedrock-connect/players:/app/players:rw"
      ];
      # Host networking so BedrockConnect's NetherNet signaling advertises the
      # host's LAN address (it has no advertise-address setting); it binds
      # TCP+UDP 19132 directly.
      log-driver = "journald";
      extraOptions = [ "--network=host" ];
    };
    mc-java = {
      image = "itzg/minecraft-server";
      pull = "newer";
      environment = {
        EULA = "TRUE";
        SERVER_NAME = javaServerName;
        TYPE = "PAPER";
        TZ = "America/Boise";
        VERSION = "LATEST";
        PLUGINS = "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
          https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
          ";
        PATCH_DEFINITIONS = "/patches";
      };
      volumes = [
        "/opt/minecraft/minecraft-server/data:/data:rw"
        "${geyserPatches}:/patches:ro"
      ];
      ports = [
        "${toString javaPort}:25565/tcp"
        "${toString geyserPort}:19132/tcp"
        "${toString geyserPort}:19132/udp"
      ];
      log-driver = "journald";
      extraOptions = [ "--network-alias=mc-java" ];
    };
  };
}
