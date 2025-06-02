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
  opts.kb-input.enable = true;

  # Bootloader.
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

  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver # LIBVA_DRIVER_NAME=iHD
  ];

  networking.hostName = "Yura-PC"; # Define your hostname.
  networking.hostId = "110a2814"; # Required for ZFS.

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
