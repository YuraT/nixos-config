# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration-vm.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.plymouth.theme = "breeze";
  boot.kernelParams = [
    "sysrq_always_enabled=1"
  ];

  boot.loader.timeout = 3;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.extraModulePackages = with config.boot.kernelPackages; [ zfs ];

  environment.etc.hosts.mode = "0644";

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.sshd.enable = true;
  services.flatpak.enable = true;

  services.xserver.xkb.extraLayouts = {
    minimak-4 = {
      description = "English (US, Minimak-4)";
      languages = [ "eng" ];
      # symbolsFile = /etc/nixos/minimak;
      symbolsFile = ./minimak;
    };
    minimak-8 = {
      description = "English (US, Minimak-8)";
      languages = [ "eng" ];
      # symbolsFile = /etc/nixos/minimak;
      symbolsFile = ./minimak;
    };
    minimak-12 = {
      description = "English (US, Minimak-12)";
      languages = [ "eng" ];
      # symbolsFile = /etc/nixos/minimak;
      symbolsFile = ./minimak;
    };
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.plasma6Support = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
 };


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups = {
    cazzzer = {
      gid = 1000;
    };
  };
  users.users.cazzzer = {
    isNormalUser = true;
    description = "Yura";
    uid = 1000;
    group = "cazzzer";
    extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" ];
    packages = with pkgs; [
      # Python
      # python3
      # poetry

      # Haskell
      # haskellPackages.ghc
      # haskellPackages.stack

      # Node
      # nodejs_22
      # pnpm
      # bun
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.lazygit.enable = true;
  programs.neovim.enable = true;

  # https://discourse.nixos.org/t/firefox-does-not-use-kde-window-decorations-and-cursor/32132/3
  # programs.dconf.enable = true;
  # programs.firefox = {
    # enable = true;
    # preferences = {
      # "widget.use-xdg-desktop-portal.file-picker" = 1;
      # "widget.use-xdg-desktop-portal.mime-handler" = 1;
    # };
  # };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # https://github.com/flatpak/flatpak/issues/2861
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  workarounds.flatpak.enable = true;
  fonts.packages = with pkgs; [ nerd-fonts.fantasque-sans-mono ];

  environment.systemPackages = with pkgs; [
    bat
    # bluez
    darkman
    dust
    efibootmgr
    eza
    fastfetch
    fd
    # flatpak
    host-spawn # for flatpaks
    kdePackages.flatpak-kcm
    kdePackages.filelight
    kdePackages.kate
    kdePackages.yakuake
    # git
    gnumake
    helix
    htop
    mediainfo
    micro
    mpv
    neofetch
    # neovim
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    ripgrep
    starship
    tealdeer
    tela-circle-icon-theme
    fantasque-sans-mono
    jetbrains-mono
    waypipe
    whois
    # wireshark
    yt-dlp
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.etc."current-system-packages".text =
    let
      packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
      formatted;

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
#   networking.firewall.allowedTCPPorts = [ 8080 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
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
