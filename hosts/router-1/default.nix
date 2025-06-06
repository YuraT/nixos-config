{
  imports = [
    ../hw-vm.nix
  ];

  router = {
    enableDesktop = false;
    enableDhcpClient = false;
    wanMAC = "bc:24:11:af:bd:84";
    lanMAC = "bc:24:11:38:b1:91";
    wanLL = "fe80::be24:11ff:feaf:bd84";
    lanLL = "fe80::be24:11ff:fe38:b191";
    defaultToken = 251;

    pdFromWan = "fd46:fbbe:ca55:100";
    wanAddr4 = "192.168.1.63";
    wanGw4 = "192.168.1.254";
  };

  networking.hostName = "grouty";

  # override hw-vm.nix default
  networking.useDHCP = false;
}
