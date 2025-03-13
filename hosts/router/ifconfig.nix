{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;
  links = vars.links;
  ifs = vars.ifs;
  pdFromWan = vars.pdFromWan;
  ulaPrefix = vars.ulaPrefix;

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
      IPv6SendRA = (ifObj.name != ifs.lan10.name);  # TODO: temporary test, remove
      Address = [ ifObj.addr4Sized ifObj.addr6Sized ifObj.ulaAddrSized ];
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
          Token = [ "static:${ifObj.ulaToken}" ];
      }
    ];
    ipv6RoutePrefixes = [ { Route = "${ulaPrefix}::/48"; } ];
    ipv6SendRAConfig = {
      # don't manage the att box subnet
      # should work fine either way though
      Managed = (ifObj.p6 != "${pdFromWan}0");
      OtherInformation = (ifObj.p6 != "${pdFromWan}0");
      EmitDNS = true;
      DNS = [ ifObj.ulaAddr ];
    };
  };

in
{
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
      duid
      ipv6only
      nohook resolv.conf, yp, hostname, ntp
      nogateway
      option rapid_commit

      # this doesn't play well with networkd
      # ia_na
      # ia_pd 1 ${ifs.lan.name}/0
      # ia_pd 2 ${ifs.lan10.name}/0
      # ia_pd 3 ${ifs.lan20.name}/0

      # request the leases just for routing (so that the att box knows we're here)
      # actual ip assignments are static, based on $pdFromWan
      ia_pd 1/${ifs.lan.net6} -
      # ia_pd 10/${ifs.lan10.net6} -
      # ia_pd 20/${pdFromWan}d::/64 -  # for opnsense (legacy services)
      ia_pd 30/${ifs.lan30.net6} -
      ia_pd 40/${ifs.lan40.net6} -
      ia_pd 50/${ifs.lan50.net6} -
      # ia_pd 7 -
      # ia_pd 8 -
  '';

  systemd.timers."restart-networkd" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "restart-networkd.service";
      };
  };

  systemd.services."restart-networkd" = {
    script = ''
      set -eu
      ${pkgs.systemd}/bin/systemctl restart systemd-networkd
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

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
        matchConfig.PermanentMACAddress = links.wanMAC;
        linkConfig.Name = ifs.wan.name;
      };
      "10-lan" = {
        matchConfig.PermanentMACAddress = links.lanMAC;
        linkConfig.Name = ifs.lan.name;
      };
    };

    netdevs = {
      # "10-vlan10" = mkVlanDev { id = 10; name = ifs.lan10.name; };
      "10-vlan20" = mkVlanDev { id = 20; name = ifs.lan20.name; };
      "10-vlan30" = mkVlanDev { id = 30; name = ifs.lan30.name; };
      "10-vlan40" = mkVlanDev { id = 40; name = ifs.lan40.name; };
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
        routes = [
          { Gateway = ifs.wan.gw4; }
          { Gateway = ifs.wan.gw6; }
        ];
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      "20-lan" = (mkLanConfig ifs.lan) // {
        vlan = [
          # ifs.lan10.name
          ifs.lan20.name
          ifs.lan30.name
          ifs.lan40.name
          ifs.lan50.name
        ];
      };
      # "30-vlan10" = mkLanConfig ifs.lan10;
      "30-vlan20" = mkLanConfig ifs.lan20 // {
        routes = [
          {
            # OPNsense subnet route
            Destination = "${pdFromWan}d::/64";
            Gateway = "fe80::1efd:8ff:fe71:954e";
          }
        ];
      };
      "30-vlan30" = mkLanConfig ifs.lan30;
      "30-vlan40" = mkLanConfig ifs.lan40;
      "30-vlan50" = mkLanConfig ifs.lan50;
    };
  };

  networking.interfaces = {
#    ${ifs.lan10.name} = {
#      ipv4.addresses = [ { address = ifs.lan10.addr4; prefixLength = ifs.lan10.p4Size; } ];
#      ipv6.addresses = [
#        {
#          address = ifs.lan10.addr6;
#          prefixLength = ifs.lan10.p6Size;
#        }
#        {
#          address = ifs.lan10.ulaAddr;
#          prefixLength = ifs.lan10.ulaSize;
#        }
#      ];
#    };
  };
  networking.dhcpcd.allowInterfaces = [ ifs.wan.name ];

  services.radvd.enable = false;
  services.radvd.config = ''
    interface ${ifs.lan10.name} {
      RDNSS ${ifs.lan.ulaAddr} {
      };
      AdvSendAdvert on;
      # MinRtrAdvInterval 3;
      # MaxRtrAdvInterval 10;
      AdvManagedFlag on;
      # AdvOtherConfigFlag on;
      prefix ${ifs.lan10.net6} {
        AdvOnLink on;
        AdvAutonomous on;
      };
      prefix ${ifs.lan10.ulaNet} {
        AdvOnLink on;
        AdvAutonomous on;
      };
      route ${ulaPrefix}::/48 {
      };
    };
  '';
}
