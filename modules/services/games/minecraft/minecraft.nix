{
  flake.modules.nixos.minecraft = {
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
        "PLUGINS" =
          "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
    https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
    ";
        "SERVER_NAME" = "Hendoboom Zone";
        "TYPE" = "PAPER";
        "TZ" = "America/Boise";
        "VERSION" = "1.21.8";
      };
      volumes = [
        "/opt/minecraft/minecraft-server/data:/data:rw"
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
}
