{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix config;
  domain = vars.domain;
  ldomain = vars.ldomain;
  sysdomain = vars.sysdomain;
  ifs = vars.ifs;

  alpinaDomains = [
    "|"
    "|nc."
    "|sonarr."
    "|radarr."
    "|prowlarr."
    "|qbit."
    "|gitea."
    "|traefik."
    "|auth."
    "||s3."
    "|minio."
    "|jellyfin."
    "|whoami."
    "|grafana."
    "|influxdb."
    "|uptime."
    "|opnsense."
    "|vpgen."
    "|woodpecker."
    "||pgrok."
    "|sync."
  ];
in
{
  # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
  # For upstream quic dns
  boot.kernel.sysctl."net.core.wmem_max" = 7500000;
  boot.kernel.sysctl."net.core.rmem_max" = 7500000;

  services.resolved.enable = false;
  networking.resolvconf.enable = true;
  networking.resolvconf.useLocalResolver = true;

  services.adguardhome.enable = true;
  services.adguardhome.mutableSettings = false;
  # https://github.com/AdguardTeam/Adguardhome/wiki/Configuration
  services.adguardhome.settings = {
    querylog.interval = "168h"; # 7 days
    dns = {
      # Disable rate limit, default of 20 is too low
      # https://github.com/AdguardTeam/AdGuardHome/issues/6726
      ratelimit = 0;
      enable_dnssec = true;
      bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
      upstream_dns = [
        # Default upstreams
        "quic://p0.freedns.controld.com"
        "tls://one.one.one.one"
        "tls://dns.quad9.net"

        # Adguard uses upstream and not rewrite rules to resolve cname rewrites,
        # and obviously my sysdomain entries don't exist in cloudflare.
        "[/${sysdomain}/][::1]"           # Sys domains to self (for cname rewrites)

        "[/${ldomain}/][::1]:1053"        # Local domains to Knot (ddns)
        "[/home/][${ifs.lan.ulaPrefix}::250]"  # .home domains to opnsense (temporary)
      ];
    };
    # https://adguard-dns.io/kb/general/dns-filtering-syntax/
    user_rules = [
      # DNS rewrites
      "|grouter.${domain}^$dnsrewrite=${ifs.lan.ulaAddr}"
      "|pve-1.${sysdomain}^$dnsrewrite=${ifs.lan.p4}.5"
      "|pve-1.${sysdomain}^$dnsrewrite=${ifs.lan.ulaPrefix}::5:1"
      "|pve-3.${sysdomain}^$dnsrewrite=${ifs.lan.p4}.7"
      "|pve-3.${sysdomain}^$dnsrewrite=${ifs.lan.ulaPrefix}::7:1"
      "|truenas.${sysdomain}^$dnsrewrite=${ifs.lan.p4}.10"
      "|truenas.${sysdomain}^$dnsrewrite=${ifs.lan.ulaPrefix}::20d0:43ff:fec6:3192"
      "|debbi.${sysdomain}^$dnsrewrite=${ifs.lan.p4}.11"
      "|debbi.${sysdomain}^$dnsrewrite=${ifs.lan.ulaPrefix}::11:1"
      "|etappi.${sysdomain}^$dnsrewrite=${ifs.lan.p4}.12"
      "|etappi.${sysdomain}^$dnsrewrite=${ifs.lan.ulaPrefix}::12:1"

      "|hass.${domain}^$dnsrewrite=${ifs.lan.ulaAddr}"

      # Lab DNS rewrites
      "||lab.${domain}^$dnsrewrite=etappi.${sysdomain}"

      # Allowed exceptions
      "@@||googleads.g.doubleclick.net"
      "@@||stats.grafana.org"
    ]
      # Alpina DNS rewrites
      ++ map (host: "${host}${domain}^$dnsrewrite=debbi.${sysdomain}") alpinaDomains;
  };

  services.knot.enable = true;
  services.knot.settings = {
    # server.listen = "0.0.0.0@1053";
    server.listen = "::1@1053";
    zone = [
      {
        domain = ldomain;
        storage = "/var/lib/knot/zones";
        file = "${ldomain}.zone";
        acl = [ "allow_localhost_update" ];
      }
    ];
    acl = [
      {
        id = "allow_localhost_update";
        address = [ "::1" "127.0.0.1" ];
        action = [ "update" ];
      }
    ];
  };
  # Ensure the zone file exists
  system.activationScripts.knotZoneFile = ''
    ZONE_DIR="/var/lib/knot/zones"
    ZONE_FILE="$ZONE_DIR/${ldomain}.zone"

    # Create the directory if it doesn't exist
    mkdir -p "$ZONE_DIR"

    # Check if the zone file exists
    if [ ! -f "$ZONE_FILE" ]; then
      # Create the zone file with a basic SOA record
      # Serial; Refresh; Retry; Expire; Negative Cache TTL;
      echo "${ldomain}. 3600 SOA ns.${ldomain}. admin.${ldomain}. 1 86400 900 691200 3600" > "$ZONE_FILE"
      echo "Created new zone file: $ZONE_FILE"
    else
      echo "Zone file already exists: $ZONE_FILE"
    fi

    # Ensure proper ownership and permissions
    chown -R knot:knot "/var/lib/knot"
    chmod 644 "$ZONE_FILE"
  '';
}
