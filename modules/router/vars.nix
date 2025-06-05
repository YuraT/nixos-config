config:
let
  cfg = config.router;
  mkIfConfig = {
    name_,
    domain_,
    p4_,  # /24
    p4Size_ ? 24,
    p6_,  # /64
    p6Size_ ? 64,
    ulaPrefix_,  # /64
    ulaSize_ ? 64,
    token? cfg.defaultToken,
    ip6Token_? "::${toString token}",
    ulaToken_? "::${toString token}",
    }: rec {
      name = name_;
      domain = domain_;
      p4 = p4_;
      p4Size = p4Size_;
      net4 = "${p4}.0/${toString p4Size}";
      addr4 = "${p4}.${toString token}";
      addr4Sized = "${addr4}/${toString p4Size}";
      p6 = p6_;
      p6Size = p6Size_;
      net6 = "${p6}::/${toString p6Size}";
      ip6Token = ip6Token_;
      addr6 = "${p6}${ip6Token}";
      addr6Sized = "${addr6}/${toString p6Size}";
      ulaPrefix = ulaPrefix_;
      ulaSize = ulaSize_;
      ulaNet = "${ulaPrefix}::/${toString ulaSize}";
      ulaToken = ulaToken_;
      ulaAddr = "${ulaPrefix}${ulaToken}";
      ulaAddrSized = "${ulaAddr}/${toString ulaSize}";
    };
in
rec {
  pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFobB87yYVwhuYrA+tfztLuks3s9jZOqEFktwGw1mo83 root@grouter";
  domain = "cazzzer.com";
  ldomain = "l.${domain}";
  sysdomain = "sys.${domain}";
  links = {
    wanMAC = cfg.wanMAC;
    lanMAC = cfg.lanMAC;
    wanLL = cfg.wanLL;
    lanLL = cfg.lanLL;
  };

  p4 = "10.17";                      # .0.0/16
  pdFromWan = cfg.pdFromWan;         # ::/60
  ulaPrefix = "fdab:07d3:581d";      # ::/48
  ifs = rec {
    wan = rec {
      name = "wan";
      addr4 = cfg.wanAddr4;
      addr4Sized = "${addr4}/24";
      gw4 = cfg.wanGw4;
    };
    lan = mkIfConfig {
      name_ = "lan";
      domain_ = "lan.${ldomain}";
      p4_ = "${p4}.1";                   # .0/24
      p6_ = "${pdFromWan}f";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0001";  # ::/64
    };
    lan10 = mkIfConfig {
      name_ = "${lan.name}.10";
      domain_ = "lab.${ldomain}";
      p4_ = "${p4}.10";                  # .0/24
      p6_ = "${pdFromWan}e";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0010";  # ::/64
    };
    lan20 = mkIfConfig {
      name_ = "${lan.name}.20";
      domain_ = "life.${ldomain}";
      p4_ = "${p4}.20";                  # .0/24
      p6_ = "${pdFromWan}0";             # ::/64 managed by Att box
      ulaPrefix_ = "${ulaPrefix}:0020";  # ::/64
      ip6Token_ = "::1:${toString cfg.defaultToken}";  # override ipv6 for lan20, since the Att box uses ::1 here
    };
    lan30 = mkIfConfig {
      name_ = "${lan.name}.30";
      domain_ = "iot.${ldomain}";
      p4_ = "${p4}.30";                  # .0/24
      p6_ = "${pdFromWan}c";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0030";  # ::/64
    };
    lan40 = mkIfConfig {
      name_ = "${lan.name}.40";
      domain_ = "kube.${ldomain}";
      p4_ = "${p4}.40";                  # .0/24
      p6_ = "${pdFromWan}b";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0040";  # ::/64
    };
    lan50 = mkIfConfig {
      name_ = "${lan.name}.50";
      domain_ = "prox.${ldomain}";
      p4_ = "${p4}.50";                  # .0/24
      p6_ = "${pdFromWan}a";             # ::/64
      ulaPrefix_ = "${ulaPrefix}:0050";  # ::/64
    };
    wg0 = mkIfConfig {
      name_ = "wg0";
      domain_ = "wg0.${ldomain}";
      p4_ = "10.18.16";  # .0/24
      p6_ = "${pdFromWan}9:0:6";  # ::/96
      p6Size_ = 96;
      ulaPrefix_ = "${ulaPrefix}:0100:0:6";  # ::/96
      ulaSize_ = 96;
    } // {
      listenPort = 51944;
    };
  };

  extra = {
    opnsense = rec {
      addr4 = "${ifs.lan.p4}.250";
      ulaAddr = "${ifs.lan.ulaPrefix}::250";
      p6 = "${pdFromWan}d";
      net6 = "${p6}::/64";
      # VPN routes on opnsense
      routes = [
        {
          Destination = "10.6.0.0/24";
          Gateway = addr4;
        }
        {
          Destination = "10.18.0.0/20";
          Gateway = addr4;
        }
        {
          Destination = net6;
          Gateway = ulaAddr;
        }
      ];
    };
  };
}
