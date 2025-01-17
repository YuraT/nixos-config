{ config, lib, pkgs, ... }:
let
  # TODO: ULAs for most things
  # TODO: proper aliases
  # TODO: refactor the crap out of everything

  if_wan = "wan";
  if_lan = "lan";
  if_lan10 = "lan.10";
  if_lan20 = "lan.20";

  lan_p4 = "10.19.1"; # .0/24
  lan10_p4 = "10.19.10"; # .0/24
  lan20_p4 = "10.19.20"; # .0/24

  pd_from_wan = ""; # ::/60
  lan_p6 = "${pd_from_wan}9"; # ::/64
  lan10_p6 = "${pd_from_wan}a"; # ::/64
  lan20_p6 = "${pd_from_wan}2"; # ::/64

  ula_p = "fdab:07d3:581d"; # ::/48
  ula_p_lan = "${ula_p}:0000"; # ::/56
  ula_p_lan10 = "${ula_p}:1000"; # ::/56
  ula_p_lan20 = "${ula_p}:2000"; # ::/56
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

  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.growPartition = true;

  environment.etc.hosts.mode = "0644";
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

    interface ${if_wan}
      ipv6rs
      dhcp6

      # this doesn't play well with networkd
      # ia_na
      # ia_pd 1 ${if_lan}/0
      # ia_pd 2 ${if_lan10}/0
      # ia_pd 3 ${if_lan20}/0

      # request the leases just for routing (so that the att box knows we're here)
      # actual ip assignments are static, based on $pd_from_wan
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
        linkConfig.Name = if_wan;
      };
      "10-lan" = {
        matchConfig.PermanentMACAddress = "bc:24:11:83:d8:de";
        linkConfig.Name = if_lan;
      };
    };

    netdevs = {
      "10-vlan10" = {
        netdevConfig = {
          Kind = "vlan";
          Name = if_lan10;
        };
        vlanConfig.Id = 10;
      };
      "10-vlan20" = {
        netdevConfig = {
          Kind = "vlan";
          Name = if_lan20;
        };
        vlanConfig.Id = 20;
      };
    };

    networks = {
      "10-wan" = {
        matchConfig.Name = if_wan;
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          # let dhcpcd handle this
          IPv6AcceptRA = false;
        };
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      "20-lan" = {
        matchConfig.Name = "lan";
        vlan = [
          if_lan10
          if_lan20
        ];
        networkConfig = {
          IPv4Forwarding = true;
          IPv6SendRA = true;
          Address = [ "${lan_p4}.1/24" ];
        };
        ipv6Prefixes = [
          {
            # AddressAutoconfiguration = false;
            Prefix = "${lan_p6}::/64";
            Assign = true;
            Token = [ "static:::1" "eui64" ];
          }
          {
            Prefix = "${ula_p_lan}::/64";
            Assign = true;
            Token = [ "static:::1" "eui64" ];
          }
        ];
        ipv6SendRAConfig = {
          Managed = true;
          OtherInformation = true;
          EmitDNS = true;
          DNS = [ "${lan_p6}::1" ];
        };
      };
      "30-vlan10"  = {
        matchConfig.Name = if_lan10;
        networkConfig = {
          IPv6SendRA = true;
          Address = [ "${lan10_p4}.1/24" ];
        };
        ipv6Prefixes = [
          {
            Prefix = "${lan10_p6}::/64";
            Assign = true;
            Token = [ "static:::1" "eui64" ];
          }
          {
            Prefix = "${ula_p_lan10}::/64";
            Assign = true;
            Token = [ "static:::1" "eui64" ];
          }
        ];
      };
      "30-vlan20"  = {
        matchConfig.Name = if_lan20;
        networkConfig = {
          IPv6SendRA = true;
          Address = [ "${lan20_p4}.1/24" ];
        };
        ipv6Prefixes = [
          {
            Prefix = "${lan20_p6}::/64";
            Assign = true;
            Token = [ "static:::1" "eui64" ];
          }
          {
            Prefix = "${ula_p_lan20}::/64";
            Assign = true;
            Token = [ "static:::1" "eui64" ];
          }
        ];
      };
    };
  };

  networking.firewall.enable = false;
  networking.nftables.enable = true;
  networking.nftables.tables.firewall = {
    family = "inet";
    content = ''
      define WAN_IF = "${if_wan}"
      define LAN_IF = "${if_lan}"
      define LAN_IPV4_SUBNET = ${lan_p4}.0/24
      define LAN_IPV6_SUBNET = ${lan_p6}::/64
      define LAN_IPV4_HOST = ${lan_p4}.100
      define LAN_IPV6_HOST = ${lan_p6}::1:1000

      define ALLOWED_TCP_PORTS = { ssh, 19999 }
      define ALLOWED_UDP_PORTS = { 53 }

      chain input {
          type filter hook input priority filter; policy drop;
          # type filter hook input priority filter; policy accept;

          # Allow established and related connections
          ct state established,related accept

          # Allow all traffic from loopback interface
          iifname lo accept

          # Allow ICMPv6 on link local addrs
          ip6 nexthdr icmpv6 ip6 saddr fe80::/10 accept
          ip6 nexthdr icmpv6 ip6 daddr fe80::/10 accept # TODO: not sure if necessary

          # Allow all ICMPv6 from LAN
          iifname $LAN_IF ip6 saddr $LAN_IPV6_SUBNET ip6 nexthdr icmpv6 accept
          # Allow DHCPv6 client traffic
          ip6 daddr { fe80::/10, ff02::/16 } udp dport dhcpv6-server accept

          # Allow all ICMP from LAN
          iifname $LAN_IF ip saddr $LAN_IPV4_SUBNET ip protocol icmp accept

          # Allow specific services from LAN
          iifname $LAN_IF ip saddr $LAN_IPV4_SUBNET tcp dport $ALLOWED_TCP_PORTS accept
          iifname $LAN_IF ip6 saddr $LAN_IPV6_SUBNET tcp dport $ALLOWED_TCP_PORTS accept
          iifname $LAN_IF ip saddr $LAN_IPV4_SUBNET udp dport $ALLOWED_UDP_PORTS accept
          iifname $LAN_IF ip6 saddr $LAN_IPV6_SUBNET udp dport $ALLOWED_UDP_PORTS accept

          # Allow SSH from WAN (if needed)
          iifname $WAN_IF tcp dport ssh accept
      }

      chain forward {
          type filter hook forward priority filter; policy drop;
          # type filter hook forward priority filter; policy accept;

          # Allow established and related connections
          ct state established,related accept

          # Port forwarding
          iifname $WAN_IF tcp dport https ip daddr $LAN_IPV4_HOST accept

          # Allowed IPv6 ports
          iifname $WAN_IF tcp dport https ip6 daddr $LAN_IPV6_HOST accept

          # Allow traffic from LAN to WAN
          iifname $LAN_IF ip saddr $LAN_IPV4_SUBNET oifname $WAN_IF accept
          iifname $LAN_IF ip6 saddr $LAN_IPV6_SUBNET oifname $WAN_IF accept
      }

      chain output {
          # Accept anything out of self by default
          type filter hook output priority filter; policy accept;
      }

      chain prerouting {
          # Initial step, accept by default
          type nat hook prerouting priority dstnat; policy accept;

          # Port forwarding
          iifname $WAN_IF tcp dport https dnat ip to $LAN_IPV4_HOST
      }

      chain postrouting {
          # Last step, accept by default
          type nat hook postrouting priority srcnat; policy accept;

          # Masquerade LAN addrs
          # theoretically shouldn't need to check the input interface here,
          # as it would be filtered by the forwarding rules
          oifname $WAN_IF ip saddr $LAN_IPV4_SUBNET masquerade

          # Optional IPv6 masquerading (big L if enabled)
          # oifname $WAN_IF ip6 saddr $LAN_IPV6_SUBNET masquerade
      }
    '';
  };

  services.kea.dhcp4.enable = true;
  services.kea.dhcp4.settings = {
    interfaces-config = {
      interfaces = [
        if_lan
      ];
    };
    lease-database = {
      type = "memfile";
      persist = true;
    };
    subnet4 = [
      {
        id = 1;
        subnet = "${lan_p4}.0/24";
        pools = [ { pool = "${lan_p4}.100 - ${lan_p4}.199"; } ];
        option-data = [
          {
            name = "routers";
            data = "${lan_p4}.1";
          }
          {
            name = "domain-name-servers";
            data = "${lan_p4}.1";
          }
        ];
      }
    ];
  };

  services.kea.dhcp6.enable = true;
  services.kea.dhcp6.settings = {
    interfaces-config = {
      interfaces = [
        if_lan
      ];
    };
    lease-database = {
      type = "memfile";
      persist = true;
    };
    subnet6 = [
      {
        id = 1;
        interface = if_lan;
        subnet = "${lan_p6}::/64";
        rapid-commit = true;
        pools = [ { pool = "${lan_p6}::1:1000/116"; } ];
        option-data = [
          {
            name = "dns-servers";
            data = "${lan_p6}::1";
          }
        ];
      }
    ];
  };

  services.resolved.enable = false;
  networking.resolvconf.enable = true;
  networking.resolvconf.useLocalResolver = true;
  services.coredns.enable = true;
  services.coredns.config = ''
  . {
      cache {
          prefetch 100
      }
      hosts /etc/coredns.hosts {
          fallthrough
      }
      # Quad9
      # forward . tls://[2620:fe::fe]:53 tls://9.9.9.9 tls://[2620:fe::9]:53 tls://149.112.112.112 {
      #    tls_servername dns.quad9.net

      # Cloudflare (seems to be faster)
      forward . tls://[2606:4700:4700::1112]:53 tls://1.1.1.2 tls://[2606:4700:4700::1002]:53 tls://1.0.0.2 {
          tls_servername security.cloudflare-dns.com
          health_check 5s
      }
  }
  '';

  environment.etc."coredns.hosts".text = ''
    ::1 wow.cazzzer.com hi.cazzzer.com
  '';

  services.knot.enable = true;
  services.knot.settings = {
    server = {
      # listen = "0.0.0.0@1053";
      listen = "::@1053";
    };
    # TODO: templates
    zone = [
      {
        domain = "l.cazzzer.com";
        storage = "/var/lib/knot/zones";
        file = "l.cazzzer.com.zone";
      }
    ];
  };
  # Ensure the zone file exists
  system.activationScripts.knotZoneFile = ''
    ZONE_DIR="/var/lib/knot/zones"
    ZONE_FILE="$ZONE_DIR/l.cazzzer.com.zone"

    # Create the directory if it doesn't exist
    mkdir -p "$ZONE_DIR"

    # Check if the zone file exists
    if [ ! -f "$ZONE_FILE" ]; then
      # Create the zone file with a basic SOA record
      # Serial; Refresh; Retry; Expire; Negative Cache TTL;
      cat > "$ZONE_FILE" <<EOF
  \$ORIGIN l.cazzzer.com.
  @ 3600 SOA ns admin 1 86400 900 691200 3600
  EOF
      echo "Created new zone file: $ZONE_FILE"
    else
      echo "Zone file already exists: $ZONE_FILE"
    fi

    # Ensure proper ownership and permissions
    chown -R knot:knot "/var/lib/knot"
    chmod 644 "$ZONE_FILE"
  '';

  services.netdata.enable = true;

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
