{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;
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
    settings.server.http_port = 3001;
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

  services.caddy = {
    enable = true;
    virtualHosts."grouter.${domain}".extraConfig = ''
      reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      tls internal
    '';
  };
}
