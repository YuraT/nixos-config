# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # ./hardware-configuration.nix
    ];
  mods.kb-input.enable = false;

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

  environment.etc.hosts.mode = "0644";

  # managed by cloud-init
  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;

  # VM services
  # services.cloud-init.enable = false;
  # services.cloud-init.network.enable = false;
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;

  security.sudo.wheelNeedsPassword = false;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
