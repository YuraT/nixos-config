# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];
  mods.kb-input.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.plymouth.enable = true;
  # boot.plymouth.theme = "breeze";
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "sysrq_always_enabled=1"
  ];

  # https://nixos.wiki/wiki/OSX-KVM
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    options kvm_amd emulate_invalid_guest_state=0
    options kvm ignore_msrs=1
  '';

  boot.loader.timeout = 3;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_14;

  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
    ];
  };

  environment.etc.hosts.mode = "0644";

  networking.hostName = "Yura-PC"; # Define your hostname.
  networking.hostId = "110a2814"; # Required for ZFS.
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

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # services.qemuGuest.enable = true;
  # services.spice-vdagentd.enable = true;
  services.openssh.enable = true;
  services.flatpak.enable = true;
  # services.geoclue2.enable = true;
  # location.provider = "geoclue2";
  # services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # security.pam.services.sddm.gnupg.enable = true;


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  # Install firefox.
  # programs.firefox.enable = true;
  programs.kdeconnect.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.git.lfs.enable = true;
  # https://nixos.wiki/wiki/Git
  programs.git.package = pkgs.git.override { withLibsecret = true; };
  programs.lazygit.enable = true;
  programs.neovim.enable = true;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
  # programs.starship.enable = true;
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark; # wireshark-cli by default
  programs.bat.enable = true;
  programs.htop.enable = true;

  # https://nixos.wiki/wiki/Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.package = pkgs.docker_27;

  # https://discourse.nixos.org/t/firefox-does-not-use-kde-window-decorations-and-cursor/32132/3
  # programs.dconf.enable = true;
  # programs.firefox = {
    # enable = true;
    # preferences = {
      # "widget.use-xdg-desktop-portal.file-picker" = 1;
      # "widget.use-xdg-desktop-portal.mime-handler" = 1;
    # };
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # https://github.com/flatpak/flatpak/issues/2861
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged
    # programs here, NOT in environment.systemPackages

    # For JetBrains stuff
    # https://github.com/NixOS/nixpkgs/issues/240444
  ];

  # attempt to fix flatpak firefox cjk fonts
  # fonts.fontconfig.defaultFonts.serif = [
  #   "Noto Serif"
  #   "DejaVu Serif"
  # ];
  # fonts.fontconfig.defaultFonts.sansSerif = [
  #   "Noto Sans"
  #   "DejaVu Sans"
  # ];

  workarounds.flatpak.enable = true;
  fonts.packages = with pkgs; [
    fantasque-sans-mono
    nerd-fonts.fantasque-sans-mono
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    jetbrains-mono
   ];
  # fonts.fontDir.enable = true;
  # fonts.fontconfig.allowBitmaps = false;

  environment.systemPackages = with pkgs; [
    dust
    eza
    fastfetch
    fd
    helix
    micro
    openssl
    ripgrep
    starship
    tealdeer
    transcrypt
  ] ++ [
    efibootmgr
    ffmpeg
    file
    fq
    gnumake
    ijq
    jq
    ldns
    mediainfo
    rbw
    restic
    resticprofile
    rclone
    ripgrep-all
    rustscan
    whois
    yt-dlp
  ] ++ [
    bitwarden-desktop
    darkman
    host-spawn # for flatpaks
    kdePackages.filelight
    kdePackages.flatpak-kcm
    kdePackages.kate
    kdePackages.yakuake
    # TODO: remove (replace by bitwarden-desktop)
    gcr
    gnome-keyring # config for this and some others
    mpv
    nextcloud-client
    lxqt.pavucontrol-qt
    pinentry
    tela-circle-icon-theme
    virt-viewer
    waypipe
  ] ++ [
    # jetbrains.rust-rover
    # jetbrains.goland
    jetbrains.clion
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    jetbrains.webstorm
    android-studio
    rustup
    zed-editor
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.nftables.enable = true;
  networking.firewall.allowedTCPPorts = [ 8080 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
