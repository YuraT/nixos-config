{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;
  enableDesktop = false;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./ifconfig.nix
      ./wireguard.nix
      ./firewall.nix
      ./dns.nix
      ./kea.nix
      ./glance.nix
      ./services.nix
    ];
  # Secrix for secrets management
  secrix.hostPubKey = vars.pubkey;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = [
    "sysrq_always_enabled=1"
  ];

  boot.loader.timeout = 2;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.growPartition = true;

  networking.hostName = "grouter";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  # Useful for debugging with wireshark.
  hardware.graphics.enable = true;
  services.displayManager.sddm.enable = enableDesktop;
  services.displayManager.sddm.wayland.enable = enableDesktop;
  services.desktopManager.plasma6.enable = enableDesktop;
  # No need for audio in VM
  services.pipewire.enable = false;

  # VM services
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  security.sudo.wheelNeedsPassword = false;

  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.bat.enable = true;
  programs.htop.enable = true;
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark; # wireshark-cli by default

  environment.systemPackages = with pkgs; [
    dust
    eza
    fastfetch
    fd
    kdePackages.kate
    ldns
    lsof
    micro
    mpv
    openssl
    ripgrep
    rustscan
    starship
    tealdeer
    transcrypt
    waypipe
    whois
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
