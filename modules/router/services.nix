{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix config;
  domain = vars.domain;
in
{

  # vnStat for tracking network interface stats
  services.vnstat.enable = true;

  # https://wiki.nixos.org/wiki/Prometheus
  services.prometheus = {
    enable = true;
    exporters = {
      # TODO: DNS, Kea, Knot, other exporters
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };

  # https://wiki.nixos.org/wiki/Grafana#Declarative_configuration
  services.grafana = {
    enable = true;
    settings = {
      security.allow_embedding = true;
      server = {
        http_port = 3001;
        domain = "grouter.${domain}";
        root_url = "https://%(domain)s/grafana/";
        serve_from_sub_path = true;
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
      ];
    };
  };

  secrix.system.secrets.cf-api-key.encrypted.file = ./secrets/cf-api-key.age;
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.secrix.system.secrets.cf-api-key.decrypted.path;
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
      hash = "sha256-AcWko5513hO8I0lvbCLqVbM1eWegAhoM0J0qXoWL/vI=";
    };
    virtualHosts."*.${domain}".extraConfig = ''
      encode
      tls {
          dns cloudflare {env.CF_API_KEY}
          resolvers 1.1.1.1
      }

      @grouter host grouter.${domain}
      handle @grouter {
          @grafana path /grafana /grafana/*
          handle @grafana {
              reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
          }
          redir /adghome /adghome/
          handle_path /adghome/* {
              reverse_proxy localhost:${toString config.services.adguardhome.port}
              basic_auth {
                  Bob $2a$14$HsWmmzQTN68K3vwiRAfiUuqIjKoXEXaj9TOLUtG2mO1vFpdovmyBy
              }
          }
          handle /* {
              reverse_proxy localhost:${toString config.services.glance.settings.server.port}
          }
      }

      @hass host hass.${domain}
      handle @hass {
          reverse_proxy homeassistant.4.lab.l.cazzzer.com:8123
      }
    '';
  };
}
