# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];

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

  boot.loader.timeout = 3;
  boot.loader.systemd-boot.configurationLimit = 5;

  # boot.kernelPackages = pkgs.linuxKernel.kernels.linux_6_8;
  # boot.kernelPackages = pkgs.linuxPackages_6_8;
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  # nix-prefetch-git --url https://github.com/zen-kernel/zen-kernel.git --rev v6.8.9-zen1 --fetch-submodules
  # boot.kernelPackages = let
  #   version = "6.8.9";
  #   suffix = "zen1"; # use "lqx1" for linux_lqx
  # in pkgs.linuxKernel.packagesFor (pkgs.linux_zen.override {
  #   inherit version suffix;
  #   modDirVersion = lib.versions.pad 3 "${version}-${suffix}";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "zen-kernel";
  #     repo = "zen-kernel";
  #     rev = "v${version}-${suffix}";
  #     sha256 = "1wva92wk0pxii4f6hn27kssgrz8yy38kk38w2wm5hh1qyz3ij1vj";
  #   };
  # });

  boot.extraModulePackages = with config.boot.kernelPackages; [ zfs ];

  # https://discourse.nixos.org/t/dev-zfs-has-the-wrong-permissions-after-rebooting/48737
  # environment.etc."tmpfiles.d/zfs.conf".text = ''
  # z /dev/zfs          0666 - -     -
  # '';

  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
    ];
  };
  # environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver

  networking.hostName = "Yura-PC"; # Define your hostname.
  networking.hostId = "110a2814"; # Required for ZFS.
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

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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
  services.sshd.enable = true;
  services.flatpak.enable = true;
  # services.geoclue2.enable = true;
  location.provider = "geoclue2";
  # services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  # security.pam.services.sddm.gnupg.enable = true;

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
    extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" "geoclue" ];
    packages = with pkgs; [
      python312Packages.torch

      kdePackages.kate
      kdePackages.yakuake
      python3
      poetry

      # Haskell
      haskellPackages.ghc
      haskellPackages.stack

      # Node
      nodejs_22
      pnpm
      bun

      # yin_yang deps, f*** this packaging s***
      python312Packages.systemd
      python312Packages.pyside6
      python312Packages.dateutils
      python312Packages.psutil
      libnotify
      # thunderbird
    ];
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  # Install firefox.
  programs.firefox.enable = true;
  programs.kdeconnect.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  # https://nixos.wiki/wiki/Git
  programs.git.package = pkgs.git.override { withLibsecret = true; };
  programs.lazygit.enable = true;
  programs.neovim.enable = true;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;
  # programs.starship.enable = true;
  programs.wireshark.enable = true;

  # https://nixos.wiki/wiki/Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.package = pkgs.docker_27;
  virtualisation.docker.storageDriver = "zfs";
  

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

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged 
    # programs here, NOT in environment.systemPackages
    
    # For JetBrains stuff
    # https://github.com/NixOS/nixpkgs/issues/240444
    curl
    expat
    fontconfig
    freetype
    fuse
    fuse3
    glib
    icu
    libclang.lib
    libdbusmenu
    libsecret
    libxcrypt-legacy
    libxml2
    nss
    openssl
    python3
    stdenv.cc.cc
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xz
    zlib
  ];

  # attempt to fix flatpak firefox cjk fonts 
  # fonts.fontconfig.defaultFonts.serif = [
  #   "Noto Serif"
  #   "DejaVu Serif"
  # ];
  
  environment.systemPackages = with pkgs; [
    level-zero
    oneDNN
    python312Packages.torch
    # zfs
    # fish

    bat
    # bluez
#     docker_27
#     docker-compose
    dust
    efibootmgr
    eza
    fastfetch
    fd
    # flatpak
    kdePackages.flatpak-kcm
    kdePackages.filelight
    # git
    gcr
    gnome-keyring # config for this and some others
    gnumake
    helix
    htop
    jetbrains-toolbox # or maybe do invidual ones?
    # jetbrains.rust-rover
    # jetbrains.pycharm-professional
    # jetbrains.webstorm
    mediainfo
    micro
    mpv
    neofetch
    # neovim
    nextcloud-client
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    lxqt.pavucontrol-qt
    pinentry
    rbw
    ripgrep
    rustup
    starship
    tealdeer
    tela-circle-icon-theme
    fantasque-sans-mono
    jetbrains-mono
    virt-viewer
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
  # networking.firewall.allowedTCPPorts = [ ... ];
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
