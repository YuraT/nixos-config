{
  imports = [
    ./hardware-configuration.nix
    ./private.nix
  ];

  router = {
    enableDesktop = false;
    enableDhcpClient = true;
    wanMAC = "bc:24:11:4f:c9:c4";
    lanMAC = "bc:24:11:83:d8:de";
    wanLL = "fe80::be24:11ff:fe4f:c9c4";
    lanLL = "fe80::be24:11ff:fe83:d8de";
    defaultToken = 1;
  };

  networking.hostName = "grouter";
}
