{ lib, config, ... }:

with lib;

{
  options = {
    router = {
      enableDesktop = mkOption {
        type = types.bool;
        default = false;
        description = "Enable desktop environment for debugging";
      };

      enableDhcpClient = mkOption {
        type = types.bool;
        default = false;
        description = "Enable DHCP client (should only be set on the main router)";
      };

      wanMAC = mkOption {
        type = types.str;
        example = "bc:24:11:4f:c9:c4";
        description = "WAN interface MAC address";
      };

      lanMAC = mkOption {
        type = types.str;
        example = "bc:24:11:83:d8:de";
        description = "LAN interface MAC address";
      };

      wanLL = mkOption {
          type = types.str;
          example = "fe80::be24:11ff:fe4f:c9c4";
          description = "WAN IPv6 link-local address";
      };

      lanLL = mkOption {
          type = types.str;
          example = "fe80::be24:11ff:fe83:d8de";
          description = "LAN IPv6 link-local address";
      };

      defaultToken = mkOption {
        type = types.int;
        default = 1;
        description = "Default token for interface addressing";
      };

      wanAddr4 = mkOption {
        type = types.str;
        example = "192.168.1.61";
        description = "WAN IPv4 address";
      };

      wanGw4 = mkOption {
        type = types.str;
        example = "192.168.1.254";
        description = "WAN IPv4 gateway";
      };

      pdFromWan = mkOption {
        type = types.str;
        example = "2001:db8:0:000";
        description = "IPv6 prefix delegation from ISP (/60)";
      };
    };
  };
}
