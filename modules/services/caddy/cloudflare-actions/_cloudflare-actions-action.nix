{ ... }:
{
  "fail2ban/action.d/caddy-cloudflare.conf".text = ''
    [Definition]
    actioncheck = test -n "$CLOUDFLARE_API_TOKEN" -a -n "''${CLOUDFLARE_ZONE_ID:-$CLOUDFLARE_ACCOUNT_ID}"

    actionban = /etc/fail2ban/caddy-cloudflare-ban.sh <ip> <name>

    actionunban = /etc/fail2ban/caddy-cloudflare-unban.sh <ip> <name>
  '';
}
