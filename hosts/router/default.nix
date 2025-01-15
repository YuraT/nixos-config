# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  lan_ip6 = "fd97:530d:73ec:f00::";
in
{
  imports =
    [ # Include the results of the hardware scan.
     ./hardware-configuration.nix
    ];
  mods.kb-input.enable = false;
  boot.growPartition = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.plymouth.theme = "breeze";
  boot.kernelParams = [
    "sysrq_always_enabled=1"
  ];

  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.extraModulePackages = with config.boot.kernelPackages; [ zfs ];

  environment.etc.hosts.mode = "0644";

  # managed by cloud-init
  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
#   networking.networkmanager.enable = true;

  # It is impossible to do multiple prefix requests with networkd
  # https://github.com/systemd/systemd/issues/22571
  networking.dhcpcd.enable = true;
  # https://github.com/systemd/systemd/issues/22571#issuecomment-2094905496
  # https://gist.github.com/csamsel/0f8cca3b2e64d7e4cc47819ec5ba9396
  networking.dhcpcd.extraConfig = ''
    duid
    nodelay
    ipv6only
    # noarp
    # nodhcp
    nodhcp6
    # noipv4
    # noipv4ll
    noipv6rs

    nohook resolv.conf, yp, hostname, ntp

    option rapid_commit

    interface wan
      ipv6rs
      # ipv6ra_noautoconf
      dhcp6

      # iaid 1
      # ia_na 0
      ia_na
      ia_pd 1 lan/0
      ia_pd 2 lan.10/0
      ia_pd 3 lan.20/0
  '';

  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network = {
    # This is applied by udev, not networkd
    # https://nixos.wiki/wiki/Systemd-networkd
    # https://nixos.org/manual/nixos/stable/#sec-rename-ifs
    links = {
      "10-wan" = {
        # matchConfig.Name = "enp6s18";
        matchConfig.PermanentMACAddress = "bc:24:11:4f:c9:c4";
        linkConfig.Name = "wan";
      };
      "10-lan" = {
        # matchConfig.Name = "enp6s18";
        matchConfig.PermanentMACAddress = "bc:24:11:83:d8:de";
        linkConfig.Name = "lan";
      };
    };

    netdevs = {
      "10-vlan10" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "lan.10";
        };
        vlanConfig.Id = 10;
      };
      "10-vlan20" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "lan.20";
        };
        vlanConfig.Id = 20;
      };
    };

    networks = {
      "10-wan" = {
        matchConfig.Name = "wan";
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          # let dhcpcd manage this
          IPv6AcceptRA = false;
        };
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";

      };
      "20-lan" = {
        matchConfig.Name = "lan";
        vlan = [
          "lan.10"
          "lan.20"
        ];
        networkConfig = {
          IPv6SendRA = true;
          Address = [ "10.19.1.1/24" ];
          # IPMasquerade = "ipv4";
          IPMasquerade = "both";
          # DHCPServer = true;
          # DHCPPrefixDelegation = true;
        };
#         dhcpServerConfig = {
#           PoolOffset = 100;
#           PoolSize = 100;
#         };
#         dhcpPrefixDelegationConfig = {
#           UplinkInterface = "enp6s18";
#           SubnetId = 0;
#           Token = "static:::1";
#         };
      };
      "30-vlan10"  = {
        matchConfig.Name = "lan.10";
        networkConfig = {
          IPv6SendRA = true;
        };
      };
      "30-vlan20"  = {
        matchConfig.Name = "lan.20";
        networkConfig = {
          IPv6SendRA = true;
        };
      };
    };
  };

  services.kea.dhcp4.enable = true;
  services.kea.dhcp4.settings = {
    interfaces-config = {
      interfaces = [
        "lan"
      ];
    };
    lease-database = {
      type = "memfile";
      persist = true;
    };
    subnet4 = [
      {
        id = 1;
        subnet = "10.19.1.0/24";
        pools = [ { pool = "10.19.1.100 - 10.19.1.199"; } ];
        option-data = [
          {
            name = "routers";
            data = "10.19.1.1";
          }
          {
            name = "domain-name-servers";
            data = "1.1.1.1";
          }
        ];
      }
    ];
  };

  services.kea.dhcp6.enable = true;
  services.kea.dhcp6.settings = {
    interfaces-config = {
      interfaces = [
        "lan"
      ];
    };
    lease-database = {
      type = "memfile";
      persist = true;
    };
    subnet6 = [
      {
        id = 1;
        subnet = "${lan_ip6}/64";
        pools = [ { pool = "${lan_ip6}1:1000/116"; } ];
        option-data = [
        ];
      }
    ];
  };

  services.netdata.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;

  # VM services
  services.cloud-init.enable = true;
#  services.cloud-init.network.enable = false;
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

  # Install firefox.
  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.neovim.enable = true;

  programs.bat.enable = true;
  programs.htop.enable = true;
  programs.wireshark.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # https://github.com/flatpak/flatpak/issues/2861
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

#  workarounds.flatpak.enable = true;
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    fantasque-sans-mono
    nerd-fonts.fantasque-sans-mono
    jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    dust
    eza
    fastfetch
    fd
    host-spawn # for flatpaks
    kdePackages.flatpak-kcm
    kdePackages.filelight
    kdePackages.kate
    kdePackages.yakuake
    ldns
    micro
    mpv
    ripgrep
    starship
    tealdeer
    waypipe
    whois
    zfs
  ];

  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
