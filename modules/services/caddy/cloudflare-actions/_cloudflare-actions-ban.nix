{ pkgs, ... }:
{
  "fail2ban/caddy-cloudflare-ban.sh" = {
    mode = "0750";
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      ip="$1"
      jail="''${2:-unknown-jail}"
      zone="''${CLOUDFLARE_ZONE_ID:-}"
      account="''${CLOUDFLARE_ACCOUNT_ID:-}"
      token="''${CLOUDFLARE_API_TOKEN:-}"
      scope=""
      base=""

      zone="$(printf '%s' "$zone" | ${pkgs.coreutils}/bin/tr -d '\r\n')"
      account="$(printf '%s' "$account" | ${pkgs.coreutils}/bin/tr -d '\r\n')"
      token="$(printf '%s' "$token" | ${pkgs.coreutils}/bin/tr -d '\r\n')"

      zone="''${zone#\"}"; zone="''${zone%\"}"
      account="''${account#\"}"; account="''${account%\"}"
      token="''${token#\"}"; token="''${token%\"}"
      jail="$(printf '%s' "$jail" | ${pkgs.coreutils}/bin/tr -cd 'A-Za-z0-9._:-')"
      test -n "$jail" || jail="unknown-jail"

      log_info() {
        ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p info <<<"$*"
      }

      log_err() {
        local msg="$*"
        ${pkgs.systemd}/bin/systemd-cat -t fail2ban-caddy-cloudflare -p err <<<"$msg"
        printf '%s\n' "$msg" >&2
      }

      cf_api() {
        local op="$1"
        shift
        local response
        local http
        local body
        local cf_errors

        response="$(${pkgs.curl}/bin/curl -sS "$@" -w '\n%{http_code}')"
        http="''${response##*$'\n'}"
        body="''${response%$'\n'*}"

        if test "$http" -lt 200 -o "$http" -ge 300; then
          cf_errors="$(printf '%s' "$body" | ${pkgs.jq}/bin/jq -r '(.errors // []) | map("\(.code):\(.message)") | join("; ")' 2>/dev/null || true)"
          test -n "$cf_errors" || cf_errors="unparsed response"
          log_err "$op http=$http cloudflare_errors=$cf_errors"
          return 22
        fi

        printf '%s' "$body"
      }

      if test -n "$account"; then
        scope="account:$account"
        base="https://api.cloudflare.com/client/v4/accounts/$account/firewall/access_rules/rules"
      elif test -n "$zone"; then
        scope="zone:$zone"
        base="https://api.cloudflare.com/client/v4/zones/$zone/firewall/access_rules/rules"
      else
        log_err "missing Cloudflare scope: set CLOUDFLARE_ZONE_ID or CLOUDFLARE_ACCOUNT_ID"
        exit 1
      fi

      trap 'log_err "ban failed ip=$ip scope=$scope line=$LINENO"' ERR

      test -n "$ip"
      test -n "$token"

      log_info "ban request ip=$ip scope=$scope jail=$jail"

      existing_id="$(cf_api "ban lookup failed ip=$ip scope=$scope" --get "$base" \
        --data-urlencode "mode=block" \
        --data-urlencode "configuration.target=ip" \
        --data-urlencode "configuration.value=$ip" \
        --data-urlencode "per_page=1" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        | ${pkgs.jq}/bin/jq -r '.result[0].id // empty')"

      if test -n "$existing_id"; then
        log_info "ban skipped existing rule ip=$ip rule_id=$existing_id"
        exit 0
      fi

      cf_api "ban create failed ip=$ip scope=$scope" -X POST "$base" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --data "{\"mode\":\"block\",\"configuration\":{\"target\":\"ip\",\"value\":\"$ip\"},\"notes\":\"fail2ban:$jail\"}" \
        | ${pkgs.jq}/bin/jq -e '.success == true' >/dev/null

      log_info "ban created ip=$ip"
    '';
  };
}
