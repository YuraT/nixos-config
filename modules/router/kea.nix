{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix config;
  ldomain = vars.ldomain;
  ifs = vars.ifs;

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

  # Reservations added to Kea
  reservations.lan.v4.reservations = [
    {
      hw-address = "64:66:b3:78:9c:09";
      hostname = "openwrt";
      ip-address = "${ifs.lan.p4}.2";
    }
    {
      hw-address = "40:86:cb:19:9d:70";
      hostname = "dlink-switchy";
      ip-address = "${ifs.lan.p4}.3";
    }
    {
      hw-address = "6c:cd:d6:af:4f:6f";
      hostname = "netgear-switchy";
      ip-address = "${ifs.lan.p4}.4";
    }
    {
      hw-address = "74:d4:35:1d:0e:80";
      hostname = "pve-1";
      ip-address = "${ifs.lan.p4}.5";
    }
    {
      hw-address = "00:25:90:f3:d0:e0";
      hostname = "pve-2";
      ip-address = "${ifs.lan.p4}.6";
    }
    {
      hw-address = "a8:a1:59:d0:57:87";
      hostname = "pve-3";
      ip-address = "${ifs.lan.p4}.7";
    }
    {
      hw-address = "22:d0:43:c6:31:92";
      hostname = "truenas";
      ip-address = "${ifs.lan.p4}.10";
    }
    {
      hw-address = "1e:d5:56:ec:c7:4a";
      hostname = "debbi";
      ip-address = "${ifs.lan.p4}.11";
    }
    {
      hw-address = "ee:42:75:2e:f1:a6";
      hostname = "etappi";
      ip-address = "${ifs.lan.p4}.12";
    }
  ];

  reservations.lan.v6.reservations = [
    {
      duid = "00:03:00:01:64:66:b3:78:9c:09";
      hostname = "openwrt";
      ip-addresses = [ "${ifs.lan.p6}::1:2" ];
    }
    {
      duid = "00:01:00:01:2e:c0:63:23:22:d0:43:c6:31:92";
      hostname = "truenas";
      ip-addresses = [ "${ifs.lan.p6}::10:1" ];
    }
    {
      duid = "00:02:00:00:ab:11:09:41:25:21:32:71:e3:77";
      hostname = "debbi";
      ip-addresses = [ "${ifs.lan.p6}::11:1" ];
    }
    {
      duid = "00:02:00:00:ab:11:6b:56:93:72:0b:3c:84:11";
      hostname = "etappi";
      ip-addresses = [ "${ifs.lan.p6}::12:1" ];
    }
  ];

  reservations.lan20.v4.reservations = [
    {
      # Router
      hw-address = "1c:3b:f3:da:5f:cc";
      hostname = "archer-ax3000";
      ip-address = "${ifs.lan20.p4}.2";
    }
    {
      # Printer
      hw-address = "30:cd:a7:c5:40:71";
      hostname = "SEC30CDA7C54071";
      ip-address = "${ifs.lan20.p4}.9";
    }
    {
      # 3D Printer
      hw-address = "20:f8:5e:ff:ae:5f";
      hostname = "GS_ffae5f";
      ip-address = "${ifs.lan20.p4}.11";
    }
    {
      hw-address = "70:85:c2:d8:87:3f";
      hostname = "Yura-PC";
      ip-address = "${ifs.lan20.p4}.40";
    }
  ];
in
{
  services.kea.dhcp4.enable = true;
  services.kea.dhcp4.settings = {
    interfaces-config.interfaces = [
      ifs.lan.name
      ifs.lan10.name
      ifs.lan20.name
      ifs.lan30.name
      ifs.lan40.name
      ifs.lan50.name
    ];
    dhcp-ddns.enable-updates = true;
    ddns-qualifying-suffix = "4.default.${ldomain}";
    subnet4 = [
      ((mkDhcp4Subnet 1 ifs.lan) // reservations.lan.v4)
      (mkDhcp4Subnet 10 ifs.lan10)
      ((mkDhcp4Subnet 20 ifs.lan20) // reservations.lan20.v4)
      (mkDhcp4Subnet 30 ifs.lan30)
      (mkDhcp4Subnet 40 ifs.lan40)
      (mkDhcp4Subnet 50 ifs.lan50)
    ];
  };

  services.kea.dhcp6.enable = true;
  services.kea.dhcp6.settings = {
    interfaces-config.interfaces = [
      ifs.lan.name
      ifs.lan10.name
      # ifs.lan20.name  # Managed by Att box
      ifs.lan30.name
      ifs.lan40.name
      ifs.lan50.name
    ];
    # TODO: https://kea.readthedocs.io/en/latest/arm/ddns.html#dual-stack-environments
    dhcp-ddns.enable-updates = true;
    ddns-qualifying-suffix = "6.default.${ldomain}";
    subnet6 = [
      ((mkDhcp6Subnet 1 ifs.lan) // reservations.lan.v6)
      (mkDhcp6Subnet 10 ifs.lan10)
      (mkDhcp6Subnet 30 ifs.lan30)
      (mkDhcp6Subnet 40 ifs.lan40)
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
}
