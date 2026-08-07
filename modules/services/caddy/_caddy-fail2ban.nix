{
  config,
  cfg,
  lib,
  pkgs,
  ...
}:
{
  services.fail2ban = lib.mkIf cfg.enableFail2ban {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "173.245.48.0/20"
      "103.21.244.0/22"
      "103.22.200.0/22"
      "103.31.4.0/22"
      "141.101.64.0/18"
      "108.162.192.0/18"
      "190.93.240.0/20"
      "188.114.96.0/20"
      "197.234.240.0/22"
      "198.41.128.0/17"
      "162.158.0.0/15"
      "104.16.0.0/13"
      "104.24.0.0/14"
      "172.64.0.0/13"
      "131.0.72.0/22"
      "2400:cb00::/32"
      "2606:4700::/32"
      "2803:f800::/32"
      "2405:b500::/32"
      "2405:8100::/32"
      "2a06:98c0::/29"
      "2c0f:f248::/32"
    ];
    bantime = "24h";
    bantime-increment = {
      enable = true;
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      maxtime = "168h";
      overalljails = true;
    };
    jails = {
      caddy-4xx.settings = {
        enabled = true;
        filter = "caddy-4xx";
        action = "%(action_)s[blocktype=DROP]";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=caddy.service";
        maxRetry = 5;
        findTime = "2h";
      };
      caddy-scan.settings = {
        enabled = true;
        filter = "caddy-scan";
        action = "caddy-cloudflare";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=caddy.service";
        maxRetry = 2;
        findTime = "30m";
        bantime = "168h";
      };
      caddy-unhosted-sni.settings = {
        enabled = true;
        filter = "caddy-unhosted-sni";
        action = "caddy-cloudflare";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=caddy.service";
        maxRetry = 3;
        findTime = "1h";
      };
    };
  };

  systemd.services.fail2ban.serviceConfig.EnvironmentFile = lib.mkIf cfg.enableFail2ban [
    config.sops.secrets.caddy_env.path
  ];

  environment.etc = lib.mkIf cfg.enableFail2ban (
    {
      "fail2ban/filter.d/caddy-4xx.local".text = pkgs.lib.mkDefault (
        pkgs.lib.mkAfter ''
          [Definition]
          failregex = ^(?=.*"method"\s*:\s*"(?:GET|POST|HEAD|PUT|PATCH|DELETE|OPTIONS)")(?=.*"status"\s*:\s*(?:401|403|404|405|408|429))(?=.*"headers"\s*:\s*\{.*"(?:Cf-Connecting-Ip|X-Forwarded-For)"\s*:\s*\["<HOST>(?:,[^"]*)?"\]).*$
        ''
      );
      "fail2ban/filter.d/caddy-scan.local".text = pkgs.lib.mkDefault (
        pkgs.lib.mkAfter ''
          [Definition]
          failregex = ^(?=.*"uri"\s*:\s*"[^"]*(?i:(?:wp-admin|wp-login(?:\.php)?|xmlrpc\.php|\.env(?:\.|$|\?)|\.git/config|\.DS_Store|\.svn/|\.hg/|\.bzr/|phpmyadmin|/pma(?:/|\?|$)|/cgi-bin(?:/|\?|$)|/actuator(?:/|\?|$)|/server-status(?:\?|$)|/server-info(?:\?|$)|/manager/html(?:\?|$)|/solr(?:/|\?|$)|/v2/_catalog(?:\?|$)|/(?:ecp|owa|autodiscover)(?:/|\?|$)|/boaform(?:/|\?|$)|/HNAP1(?:/|\?|$)|/(?:debug|config|admin)(?:/|\?|$)|\.(?:bak|old|orig|sql|zip|tar|gz)(?:\?|$))))(?=.*"headers"\s*:\s*\{.*"(?:Cf-Connecting-Ip|X-Forwarded-For)"\s*:\s*\["<HOST>(?:,[^"]*)?"\]).*$
        ''
      );
      "fail2ban/filter.d/caddy-unhosted-sni.local".text = pkgs.lib.mkDefault (
        pkgs.lib.mkAfter ''
          [Definition]
          failregex = ^.*http: TLS handshake error from <HOST>:\d+: no certificate available for '[^']+'.*$
        ''
      );
    }
    // import ./_caddy-cloudflare-actions.nix { inherit pkgs; }
  );
}
