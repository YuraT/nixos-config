{
  imports = [
    ../hw-vm.nix
  ];

  router = {
    enableDesktop = false;
    enableDhcpClient = false;
    wanMAC = "bc:24:11:bc:db:c1";
    lanMAC = "bc:24:11:19:2a:96";
    wanLL = "fe80::be24:11ff:febc:dbc1";
    lanLL = "fe80::be24:11ff:fe19:2a96";
    defaultToken = 252;

    pdFromWan = "fd46:fbbe:ca55:100";
    wanAddr4 = "192.168.1.64";
    wanGw4 = "192.168.1.254";
  };

  networking.hostName = "grouta";

  # override hw-vm.nix default
  networking.useDHCP = false;
}
