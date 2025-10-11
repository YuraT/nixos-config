{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix config;
  links = vars.links;
  ifs = vars.ifs;
  pdFromWan = vars.pdFromWan;
  nftIdentifiers = ''
    define ZONE_WAN_IFS = { ${ifs.wan.name} }
    define ZONE_LAN_IFS = {
        ${ifs.lan.name},
        ${ifs.lan10.name},
        ${ifs.lan20.name},
        ${ifs.lan30.name},
        ${ifs.lan40.name},
        ${ifs.lan50.name},
        ${ifs.wg0.name},
    }
    define OPNSENSE_NET6 = ${vars.extra.opnsense.net6}
    define ZONE_LAN_EXTRA_NET6 = {
        # TODO: reevaluate this statement
        ${ifs.lan20.net6},  # needed since packets can come in from wan on these addrs
        $OPNSENSE_NET6,
    }
    define RFC1918 = { 10.0.0.0/8, 172.12.0.0/12, 192.168.0.0/16 }
    define CLOUDFLARE_NET6 = {
        # https://www.cloudflare.com/ips-v6
        # TODO: figure out a better way to get addrs dynamically from url
        # perhaps building a nixos module/package that fetches the ips?
        2400:cb00::/32,
        2606:4700::/32,
        2803:f800::/32,
        2405:b500::/32,
        2405:8100::/32,
        2a06:98c0::/29,
        2c0f:f248::/32,
    }
  '';
in
{
  networking.firewall.enable = false;
  networking.nftables.enable = true;
  # networking.nftables.ruleset = nftIdentifiers; #doesn't work because it's appended to the end
  networking.nftables.tables.nat4 = {
    family = "ip";
    content = ''
      ${nftIdentifiers}
      map port_forward {
          type inet_proto . inet_service : ipv4_addr . inet_service
          elements = {
              tcp . 8006 : ${ifs.lan50.p4}.10 . 8006,
              # opnsense vpn endpoints
              # the plan is to maybe eventually move these to nixos
              udp . 18596 : ${vars.extra.opnsense.addr4} . 18596,
              udp . 48512 : ${vars.extra.opnsense.addr4} . 48512,
              udp . 40993 : ${vars.extra.opnsense.addr4} . 40993,
              udp . 45608 : ${vars.extra.opnsense.addr4} . 45608,
              udp . 35848 : ${vars.extra.opnsense.addr4} . 35848,
              udp . 48425 : ${vars.extra.opnsense.addr4} . 48425,
              # Amnezia VPN server
              udp . 37138 : ${vars.extra.amnezia.addr4} . 37138,
              # Minecruft server
              tcp . 25565 : ${vars.extra.minecruft.addr4} . 25565,
              udp . 25565 : ${vars.extra.minecruft.addr4} . 25565,
              udp . 24454 : ${vars.extra.minecruft.addr4} . 24454,
          }
      }

      chain prerouting {
          # Initial step, accept by default
          type nat hook prerouting priority dstnat; policy accept;

          # Port forwarding
          fib daddr type local dnat ip to meta l4proto . th dport map @port_forward
      }

      chain postrouting {
          # Last step, accept by default
          type nat hook postrouting priority srcnat; policy accept;

          # Masquerade LAN addrs
          oifname $ZONE_WAN_IFS ip saddr $RFC1918 masquerade
      }
    '';
  };

  # Optional IPv6 masquerading (big L if enabled, don't forget to allow forwarding)
  networking.nftables.tables.nat6 = {
    family = "ip6";
    enable = false;
    content = ''
      ${nftIdentifiers}
      chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname $ZONE_WAN_IFS ip6 saddr fd00::/8 masquerade
      }
    '';
  };

  networking.nftables.tables.firewall = {
    family = "inet";
    content = ''
      ${nftIdentifiers}
      define ALLOWED_TCP_PORTS = { ssh }
      define ALLOWED_UDP_PORTS = { ${toString vars.ifs.wg0.listenPort} }
      define ALLOWED_TCP_LAN_PORTS = { ssh, https }
      define ALLOWED_UDP_LAN_PORTS = { bootps, dhcpv6-server, domain, https }
      set port_forward_v6 {
          type inet_proto . ipv6_addr . inet_service
          elements = {
              # syncthing on alpina
              tcp . ${ifs.lan.p6}::11:1 . 22000 ,
              udp . ${ifs.lan.p6}::11:1 . 22000 ,
          }
      }
      set cloudflare_forward_v6 {
          type ipv6_addr
          elements = {
              ${ifs.lan.p6}::11:1,
          }
      }

      chain input {
          type filter hook input priority filter; policy drop;

          # Drop router adverts from self
          # peculiarity due to wan and lan20 being bridged
          # TODO: figure out a less jank way to do this
          iifname $ZONE_WAN_IFS ip6 saddr ${links.lanLL} icmpv6 type nd-router-advert log prefix "self radvt: " drop
          # iifname $ZONE_WAN_IFS ip6 saddr ${links.lanLL} ip6 nexthdr icmpv6 log prefix "self icmpv6: " drop
          # iifname $ZONE_WAN_IFS ip6 saddr ${links.lanLL} log prefix "self llv6: " drop
          # iifname $ZONE_WAN_IFS ip6 saddr ${links.lanLL} log drop
          # iifname $ZONE_LAN_IFS ip6 saddr ${links.wanLL} log drop

          # Allow established and related connections
          # All icmp stuff should (theoretically) be handled by ct related
          # https://serverfault.com/a/632363
          ct state established,related accept

          # However, that doesn't happen for router advertisements from what I can tell
          # TODO: more testing
          # Allow ICMPv6 on local addrs
          ip6 nexthdr icmpv6 ip6 saddr { fe80::/10, ${pdFromWan}0::/60 } accept
          ip6 nexthdr icmpv6 ip6 daddr fe80::/10 accept # TODO: not sure if necessary

          # Allow all traffic from loopback interface
          iif lo accept

          # Allow DHCPv6 traffic
          # I thought dhcpv6-client traffic would be accepted by established/related,
          # but apparently not.
          ip6 daddr { fe80::/10, ff02::/16 } th dport { dhcpv6-client, dhcpv6-server } accept

          # Global input rules
          tcp dport $ALLOWED_TCP_PORTS accept
          udp dport $ALLOWED_UDP_PORTS accept

          # WAN zone input rules
          iifname $ZONE_WAN_IFS jump zone_wan_input
          # LAN zone input rules
          # iifname $ZONE_LAN_IFS accept
          iifname $ZONE_LAN_IFS jump zone_lan_input
          ip6 saddr $ZONE_LAN_EXTRA_NET6 jump zone_lan_input

          # log
      }

      chain forward {
          type filter hook forward priority filter; policy drop;

          # Allow established and related connections
          ct state established,related accept

          # WAN zone forward rules
          iifname $ZONE_WAN_IFS jump zone_wan_forward
          # LAN zone forward rules
          iifname $ZONE_LAN_IFS jump zone_lan_forward
          ip6 saddr $ZONE_LAN_EXTRA_NET6 jump zone_lan_forward
      }

      chain zone_wan_input {
          # Allow specific stuff from WAN
      }

      chain zone_wan_forward {
          # Port forwarding
          ct status dnat accept

          # Allowed IPv6 ports
          meta l4proto . ip6 daddr . th dport @port_forward_v6 accept

          # Allowed IPv6 from cloudflare
          ip6 saddr $CLOUDFLARE_NET6 ip6 daddr @cloudflare_forward_v6 th dport https accept
      }

      chain zone_lan_input {
          # Allow all ICMPv6 from LAN
          ip6 nexthdr icmpv6 accept

          # Allow all ICMP from LAN
          ip protocol icmp accept

          # Allow specific services from LAN
          tcp dport $ALLOWED_TCP_LAN_PORTS accept
          udp dport $ALLOWED_UDP_LAN_PORTS accept
      }

      chain zone_lan_forward {
          # Allow port forwarded targets
          # ct status dnat accept

          # Allow all traffic from LAN to WAN, except ULAs
          oifname $ZONE_WAN_IFS ip6 saddr fd00::/8 drop  # Not sure if needed
          oifname $ZONE_WAN_IFS accept;

          # Allow traffic between LANs
          oifname $ZONE_LAN_IFS accept
      }

      chain output {
          # Accept anything out of self by default
          type filter hook output priority filter; policy accept;
          # NAT reflection
          # oif lo ip daddr != 127.0.0.0/8 dnat ip to meta l4proto . th dport map @port_forward_v4
      }
    '';
  };
}
