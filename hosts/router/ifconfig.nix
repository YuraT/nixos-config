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
      IPv6SendRA = true;
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
  # https://github.com/systemd/systemd/issues/22571#issuecomment-2094905496
  # https://gist.github.com/csamsel/0f8cca3b2e64d7e4cc47819ec5ba9396
  networking.dhcpcd.enable = true;
  networking.dhcpcd.allowInterfaces = [ ifs.wan.name ];
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf, yp, hostname, ntp

    interface ${ifs.wan.name}
      # IPv4 (Static)
      nodhcp
      noipv4ll
      static ip_address=${ifs.wan.addr4Sized}
      static routers=${ifs.wan.gw4}

      # IPv6
      duid
      ipv6rs
      dhcp6
      option rapid_commit

      # DHCPv6 addr
      ia_na

      # DHCPv6 Prefix Delegation

      # request the leases just for routing (so that the att box knows we're here)
      # actual ip assignments are static, based on $pdFromWan
      ia_pd 1/${ifs.lan.net6} -
      ia_pd 10/${ifs.lan10.net6} -
      # ia_pd 20/${pdFromWan}d::/64 -  # for opnsense (legacy services)
      ia_pd 30/${ifs.lan30.net6} -
      ia_pd 40/${ifs.lan40.net6} -
      ia_pd 50/${ifs.lan50.net6} -
      # ia_pd 7 -
      # ia_pd 8 -

      # the leases can be assigned to the interfaces,
      # but this doesn't play well with networkd
      # ia_pd 1 ${ifs.lan.name}/0
      # ia_pd 2 ${ifs.lan10.name}/0
      # ia_pd 3 ${ifs.lan20.name}/0
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
        matchConfig.PermanentMACAddress = links.wanMAC;
        linkConfig.Name = ifs.wan.name;
      };
      "10-lan" = {
        matchConfig.PermanentMACAddress = links.lanMAC;
        linkConfig.Name = ifs.lan.name;
      };
    };

    netdevs = {
      "10-vlan10" = mkVlanDev { id = 10; name = ifs.lan10.name; };
      "10-vlan20" = mkVlanDev { id = 20; name = ifs.lan20.name; };
      "10-vlan30" = mkVlanDev { id = 30; name = ifs.lan30.name; };
      "10-vlan40" = mkVlanDev { id = 40; name = ifs.lan40.name; };
      "10-vlan50" = mkVlanDev { id = 50; name = ifs.lan50.name; };
    };

    networks = {
      "10-wan" = {
        matchConfig.Name = ifs.wan.name;
        linkConfig = {
          Unmanaged = true;
          RequiredForOnline = "routable";
        };
      };
      "20-lan" = (mkLanConfig ifs.lan) // {
        vlan = [
          ifs.lan10.name
          ifs.lan20.name
          ifs.lan30.name
          ifs.lan40.name
          ifs.lan50.name
        ];
      };
      "30-vlan10" = mkLanConfig ifs.lan10;
      "30-vlan20" = mkLanConfig ifs.lan20;
      "30-vlan30" = mkLanConfig ifs.lan30;
      "30-vlan40" = mkLanConfig ifs.lan40;
      "30-vlan50" = mkLanConfig ifs.lan50;
    };
  };

  # For some reason, the interfaces stop receiving route solicitations after a while.
  # Regular router adverts still get sent out at intervals, but this breaks dhcp6 clients.
  # Restarting networkd makes it work again, I have no clue why.
  # This is jank af, but I've tried a bunch of other stuff with no success
  # and I'm giving up (for now).
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
}
