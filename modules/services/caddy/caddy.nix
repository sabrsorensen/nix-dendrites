{
  inputs,
  ...
}:
{
  flake.modules.nixos.caddy =
    {
      config,
      pkgs,
      ...
    }:
    {
      sops.secrets = {
        caddy_env = {
          owner = "caddy";
          group = "caddy";
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/caddy.env";
          key = "";
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      services = {
        caddy = {
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
            hash = "sha256-7DGnojZvcQBZ6LEjT0e5O9gZgsvEeHlQP9aKaJIs/Zg=";
          };
          enable = true;
          email = "letsencrypt@{$DOMAIN}";
          environmentFile = config.sops.secrets.caddy_env.path;
          globalConfig = ''
            acme_dns cloudflare {$CLOUDFLARE_API_KEY}
          '';
          extraConfig = ''
            (cors) {
              @cors_preflight method OPTIONS
              @cors header Origin {args[0]}

              handle @cors_preflight {
                header Access-Control-Allow-Origin "{args[0]}"
                header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE"
                header Access-Control-Allow-Headers "Content-Type"
                header Access-Control-Max-Age "3600"
                respond "" 204
              }

              handle @cors {
                header Access-Control-Allow-Origin "{args[0]}"
                header Access-Control-Expose-Headers "Link"
              }
            }
          '';
          logFormat = ''
            output stdout
            format console
            level INFO
          '';
        };
      };
    };
}
