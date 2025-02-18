{ config, lib, pkgs, ... }:
let
  domain = "cazzzer.com";
  ldomain = "l.${domain}";

  mkIfConfig = {
    name_,
    domain_,
    p4_,  # /24
    p6_,  # /64
    ulaPrefix_,  # /64
    token? 1,
    }: rec {
      name = name_;
      domain = domain_;
      p4 = p4_;
      p4Size = 24;
      net4 = "${p4}.0/${toString p4Size}";
      addr4 = "${p4}.${toString token}";
      addr4Sized = "${addr4}/${toString p4Size}";
      p6 = p6_;
      p6Size = 64;
      net6 = "${p6}::/${toString p6Size}";
      ip6Token = "::${toString token}";
      addr6 = "${p6}${ip6Token}";
      addr6Sized = "${addr6}/${toString p6Size}";
      ulaPrefix = ulaPrefix_;
      ulaSize = 64;
      ulaNet = "${ulaPrefix}::/${toString ulaSize}";
      ulaAddr = "${ulaPrefix}${ip6Token}";
      ulaAddrSized = "${ulaAddr}/${toString ulaSize}";
    };

  p4 = "10.19";                      # .0.0/16
  pdFromWan = "";  # ::/60
  ulaPrefix = "fdab:07d3:581d";      # ::/48
  ifs = rec {
    wan = rec {
      name = "wan";
      addr4 = "192.168.1.61";
      addr4Sized = "${addr4}/24";
      gw4 = "192.168.1.254";
    };
    lan = mkIfConfig {
      name_ = "lan";
      domain_ = "lan.${ldomain}";
      p4_ = "${p4}.1";                   # .0/24
      p6_ = "${pdFromWan}9";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0001";  # ::/64
    };
    lan10 = mkIfConfig {
      name_ = "${lan.name}.10";
      domain_ = "lab.${ldomain}";
      p4_ = "${p4}.10";                  # .0/24
      p6_ = "${pdFromWan}a";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0010";  # ::/64
    };
    lan20 = mkIfConfig {
      name_ = "${lan.name}.20";
      domain_ = "life.${ldomain}";
      p4_ = "${p4}.20";                  # .0/24
      p6_ = "${pdFromWan}2";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0020";  # ::/64
    };
    lan50 = mkIfConfig {
      name_ = "${lan.name}.50";
      domain_ = "prox.${ldomain}";
      p4_ = "10.17.50";                  # .0/24 TODO: change to p4 later
      p6_ = "${pdFromWan}a";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0050";  # ::/64
    };
  };

  mkVlanDev = { id, name }: {
    netdevConfig = {
      Kind = "vlan";
      Name = name;
    };
    vlanConfig.Id = id;
  };

  mkLanConfig = ifObj: {
    matchConfig.Name = ifObj.name;
    networkConfig = {
      IPv4Forwarding = true;
      IPv6SendRA = true;
      Address = [ ifObj.addr4Sized ];
    };
    ipv6Prefixes = [
      {
        Prefix = ifObj.net6;
        Assign = true;
        # Token = [ "static::1" "eui64" ];
        Token = [ "static:${ifObj.ip6Token}" ];
      }
      {
        Prefix = ifObj.ulaNet;
        Assign = true;
        Token = [ "static:${ifObj.ip6Token}" ];
      }
    ];
    ipv6SendRAConfig = {
      Managed = true;
      OtherInformation = true;
      EmitDNS = true;
      DNS = [ ifObj.ulaAddr ];
    };
  };

  mkDhcp4Subnet = id: ifObj: {
    id = id;
    subnet = ifObj.net4;
    pools = [ { pool = "${ifObj.p4}.100 - ${ifObj.p4}.199"; } ];
    ddns-qualifying-suffix = "4.${ifObj.domain}";
    option-data = [
      { name = "routers"; data = ifObj.addr4; }
      { name = "domain-name-servers"; data = ifObj.addr4; }
      { name = "domain-name"; data = "4.${ifObj.domain}"; }
    ];
  };

  mkDhcp6Subnet = id: ifObj: {
    id = id;
    interface = ifObj.name;
    subnet = ifObj.net6;
    rapid-commit = true;
    pools = [ { pool = "${ifObj.p6}::1:1000/116"; } ];
    ddns-qualifying-suffix = "6.${ifObj.domain}";
    option-data = [
      { name = "domain-search"; data = "6.${ifObj.domain}"; }
    ];
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = [
    "sysrq_always_enabled=1"
  ];

  boot.loader.timeout = 2;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.growPartition = true;

  networking.hostName = "grouter";

  # It is impossible to do multiple prefix requests with networkd,
  # so I use dhcpcd for this
  # https://github.com/systemd/systemd/issues/22571
  networking.dhcpcd.enable = true;
  # https://github.com/systemd/systemd/issues/22571#issuecomment-2094905496
  # https://gist.github.com/csamsel/0f8cca3b2e64d7e4cc47819ec5ba9396
  networking.dhcpcd.extraConfig = ''
    duid
    ipv6only
    nodhcp6
    noipv6rs
    nohook resolv.conf, yp, hostname, ntp
    option rapid_commit

    interface ${ifs.wan.name}
      ipv6rs
      dhcp6

      # this doesn't play well with networkd
      # ia_na
      # ia_pd 1 ${ifs.lan.name}/0
      # ia_pd 2 ${ifs.lan10.name}/0
      # ia_pd 3 ${ifs.lan20.name}/0

      # request the leases just for routing (so that the att box knows we're here)
      # actual ip assignments are static, based on $pdFromWan
      ia_pd 1 -
      ia_pd 2 -
      # ia_pd 3 -
      # ia_pd 4 -
      # ia_pd 5 -
      # ia_pd 6 -
      # ia_pd 7 -
      # ia_pd 8 -
  '';

  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network = {
    # Global options
    config.networkConfig = {
      IPv4Forwarding = true;
      IPv6Forwarding = true;
    };

    # This is applied by udev, not networkd
    # https://nixos.wiki/wiki/Systemd-networkd
    # https://nixos.org/manual/nixos/stable/#sec-rename-ifs
    links = {
      "10-wan" = {
        matchConfig.PermanentMACAddress = "bc:24:11:4f:c9:c4";
        linkConfig.Name = ifs.wan.name;
      };
      "10-lan" = {
        matchConfig.PermanentMACAddress = "bc:24:11:83:d8:de";
        linkConfig.Name = ifs.lan.name;
      };
    };

    netdevs = {
      # "10-vlan10" = mkVlanDev { id = 10; name = ifs.lan10.name; };
      # "10-vlan20" = mkVlanDev { id = 20; name = ifs.lan20.name; };
      "10-vlan50" = mkVlanDev { id = 50; name = ifs.lan50.name; };
    };

    networks = {
      "10-wan" = {
        matchConfig.Name = ifs.wan.name;
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          # DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          # let dhcpcd handle this
          Address = [ ifs.wan.addr4Sized ];
          IPv6AcceptRA = false;
        };
        routes = [ { Gateway = ifs.wan.gw4; } ];
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      # "20-lan" = (mkLanConfig ifs.lan) // {
      "20-lan" = {
        matchConfig.Name = ifs.lan.name;
        vlan = [
          ifs.lan10.name
          ifs.lan20.name
          ifs.lan50.name
        ];
      };
      "30-vlan10" = mkLanConfig ifs.lan10;
      "30-vlan20" = mkLanConfig ifs.lan20;
      "30-vlan50" = mkLanConfig ifs.lan50;
    };
  };

  networking.firewall.enable = false;
  networking.nftables.enable = true;
  networking.nftables.tables.firewall = {
    family = "inet";
    content = ''
      define LAN_IPV4_HOST = ${ifs.lan.p4}.100
      define LAN_IPV6_HOST = ${ifs.lan.p6}::1:1000
      define ZONE_WAN_IFS = { ${ifs.wan.name} }
      define ZONE_LAN_IFS = { ${ifs.lan.name}, ${ifs.lan10.name}, ${ifs.lan20.name}, ${ifs.lan50.name} }
      define RFC1918 = { 10.0.0.0/8, 172.12.0.0/12, 192.168.0.0/16 }

      define ALLOWED_TCP_PORTS = { ssh, https }
      define ALLOWED_UDP_PORTS = { domain }

      map port_forward_v4 {
          type inet_proto . inet_service : ipv4_addr . inet_service
          elements = {
              tcp . 8006 : 10.17.50.10 . 8006
          }
      }
      set port_forward_v6 {
          type inet_proto . ipv6_addr . inet_service
          elements = {
              tcp . $LAN_IPV6_HOST . https
          }
      }

      chain input {
          type filter hook input priority filter; policy drop;

          # Allow established and related connections
          ct state established,related accept

          # Allow all traffic from loopback interface
          iif lo accept

          # Allow ICMPv6 on link local addrs
          ip6 nexthdr icmpv6 ip6 saddr fe80::/10 accept
          ip6 nexthdr icmpv6 ip6 daddr fe80::/10 accept # TODO: not sure if necessary

          # Allow DHCPv6 client traffic
          ip6 daddr { fe80::/10, ff02::/16 } udp dport dhcpv6-server accept

          # WAN zone input rules
          iifname $ZONE_WAN_IFS jump zone_wan_input
          # LAN zone input rules
          iifname $ZONE_LAN_IFS jump zone_lan_input
      }

      chain forward {
          type filter hook forward priority filter; policy drop;

          # Allow established and related connections
          ct state established,related accept

          # WAN zone forward rules
          iifname $ZONE_WAN_IFS jump zone_wan_forward
          # LAN zone forward rules
          iifname $ZONE_LAN_IFS jump zone_lan_forward
      }

      chain zone_wan_input {
          # Allow SSH from WAN (if needed)
          tcp dport ssh accept
      }

      chain zone_wan_forward {
          # Port forwarding
          ct status dnat accept

          # Allowed IPv6 ports
          meta l4proto . ip6 daddr . th dport @port_forward_v6 accept
      }

      chain zone_lan_input {
          # Allow all ICMPv6 from LAN
          ip6 nexthdr icmpv6 accept
          # Allow all ICMP from LAN
          ip protocol icmp accept

          # Allow specific services from LAN
          tcp dport $ALLOWED_TCP_PORTS accept
          udp dport $ALLOWED_UDP_PORTS accept
      }

      chain zone_lan_forward {
          # Allow port forwarded targets
          # ct status dnat accept

          # Allow all traffic from LAN to WAN, except ULAs
          oifname ${ifs.wan.name} ip6 saddr fd00::/8 drop
          oifname ${ifs.wan.name} accept;

          # Allow traffic between LANs
          oifname $ZONE_LAN_IFS accept
      }

      chain output {
          # Accept anything out of self by default
          type filter hook output priority filter; policy accept;
          # NAT reflection
          # oif lo ip daddr != 127.0.0.0/8 dnat ip to meta l4proto . th dport map @port_forward_v4
      }

      chain prerouting {
          # Initial step, accept by default
          type nat hook prerouting priority dstnat; policy accept;

          # Port forwarding
          # iifname ${ifs.wan.name} tcp dport https dnat ip to $LAN_IPV4_HOST
          # tcp dport $PROX_PORT fib daddr type local dnat ip to $PROX_HOST
          fib daddr type local dnat ip to meta l4proto . th dport map @port_forward_v4
      }

      chain postrouting {
          # Last step, accept by default
          type nat hook postrouting priority srcnat; policy accept;

          # Masquerade LAN addrs
          oifname ${ifs.wan.name} ip saddr $RFC1918 masquerade

          # Optional IPv6 masquerading (big L if enabled, don't forget to allow forwarding)
          # oifname ${ifs.wan.name} ip6 saddr fd00::/8 masquerade
      }
    '';
  };

  services.kea.dhcp4.enable = true;
  services.kea.dhcp4.settings = {
    interfaces-config.interfaces = [
      ifs.lan.name
      # ifs.lan10.name
      # ifs.lan20.name
      ifs.lan50.name
    ];
    dhcp-ddns.enable-updates = true;
    ddns-qualifying-suffix = "4.default.${ldomain}";
    subnet4 = [
      ((mkDhcp4Subnet 1 ifs.lan) // {
        reservations = [
          {
            hw-address = "bc:24:11:b7:27:4d";
            hostname = "archy";
            ip-address = "${ifs.lan.p4}.69";
          }
        ];
      })
      (mkDhcp4Subnet 50 ifs.lan50)
    ];
  };

  services.kea.dhcp6.enable = true;
  services.kea.dhcp6.settings = {
    interfaces-config.interfaces = [
      ifs.lan.name
      # ifs.lan10.name
      # ifs.lan20.name
      ifs.lan50.name
    ];
    # TODO: https://kea.readthedocs.io/en/latest/arm/ddns.html#dual-stack-environments
    dhcp-ddns.enable-updates = true;
    ddns-qualifying-suffix = "6.default.${ldomain}";
    subnet6 = [
      ((mkDhcp6Subnet 1 ifs.lan) // {
        reservations = [
          {
            duid = "00:04:59:c3:ce:9a:08:cf:fb:b7:fe:74:9c:e3:b7:44:bf:01";
            hostname = "archy";
            ip-addresses = [ "${ifs.lan.p6}::69" ];
          }
        ];
      })
      (mkDhcp6Subnet 50 ifs.lan50)
    ];
  };

  services.kea.dhcp-ddns.enable = true;
  services.kea.dhcp-ddns.settings = {
    forward-ddns.ddns-domains = [
      {
        name = "${ldomain}.";
        dns-servers = [ { ip-address = "::1"; port = 1053; } ];
      }
    ];
  };

  services.resolved.enable = false;
  networking.resolvconf.enable = true;
  networking.resolvconf.useLocalResolver = true;

  services.adguardhome.enable = true;
  services.adguardhome.mutableSettings = false;
  services.adguardhome.settings = {
    dns = {
      bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
      upstream_dns = [
        "quic://p0.freedns.controld.com"  # Default upstream
        "[/${ldomain}/][::1]:1053"        # Local domains to Knot (ddns)
      ];
    };
    # https://adguard-dns.io/kb/general/dns-filtering-syntax/
    user_rules = [
      # DNS rewrites
      "|grouter.${domain}^$dnsrewrite=${ifs.lan.ulaAddr}"

      # Allowed exceptions
      "@@||googleads.g.doubleclick.net"
    ];
  };

  services.knot.enable = true;
  services.knot.settings = {
    # server.listen = "0.0.0.0@1053";
    server.listen = "::1@1053";
    # TODO: templates
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

  # services.netdata.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  # Useful for debugging with wireshark.
  services.displayManager.sddm.enable = false;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  # No need for audio in VM
  services.pipewire.enable = false;

  # VM services
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;

  security.sudo.wheelNeedsPassword = false;

  users.groups = {
    cazzzer = {
      gid = 1000;
    };
  };
  users.users.cazzzer = {
    password = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWgEzbEjbbu96MVQzkiuCrw+UGYAXN4sRe2zM6FVopq cazzzer@Yura-PC"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIApFeLVi3BOquL0Rt+gQK2CutNHaBDQ0m4PcGWf9Bc43 cazzzer@Yura-TPX13"
    ];
    isNormalUser = true;
    description = "Yura";
    uid = 1000;
    group = "cazzzer";
    extraGroups = [ "wheel" "docker" "wireshark" ];
  };

  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.bat.enable = true;
  programs.htop.enable = true;
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark; # wireshark-cli by default

  environment.systemPackages = with pkgs; [
    dust
    eza
    fastfetch
    fd
    kdePackages.filelight
    kdePackages.kate
    kdePackages.yakuake
    ldns
    lsof
    micro
    mpv
    ripgrep
    rustscan
    starship
    tealdeer
    waypipe
    whois
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
