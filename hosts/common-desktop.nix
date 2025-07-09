{ config, lib, pkgs, ... }:

{
  opts.kb-input.enable = true;

  boot.kernelParams = [
    "sysrq_always_enabled=1"
  ];

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_15;
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 3;
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
  };

  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  hardware.graphics.enable = true;

  environment.etc.hosts.mode = "0644";

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
  };

  services.flatpak.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  programs.kdeconnect.enable = true;
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.git.lfs.enable = true;
  # https://nixos.wiki/wiki/Git
  programs.git.package = pkgs.git.override { withLibsecret = true; };
  programs.lazygit.enable = true;
  programs.neovim.enable = true;
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark; # wireshark-cli by default
  programs.bat.enable = true;
  programs.htop.enable = true;

  # https://nixos.wiki/wiki/Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.package = pkgs.docker_28;

  # https://github.com/flatpak/flatpak/issues/2861
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

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
    powertop
    rbw
    restic
    resticprofile
    rclone
    ripgrep-all
    rustscan
    whois
    wireguard-tools
    yt-dlp
  ] ++ [
    bitwarden-desktop
    darkman
    host-spawn # for flatpaks
    kdePackages.filelight
    kdePackages.flatpak-kcm
    kdePackages.kate
    kdePackages.yakuake
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
  ] ++ [
    # Python
    python3
    poetry

    # Haskell
    haskellPackages.ghc
    haskellPackages.stack

    # Node
    nodejs_22
    pnpm
    bun

    # Nix
    nil
    nixd
    nixfmt-rfc-style

    # Gleam
    gleam
    beamMinimal26Packages.erlang
  ];
}
