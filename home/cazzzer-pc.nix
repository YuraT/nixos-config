{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./common-desktop.nix
  ];

  programs.plasma.kwin.virtualDesktops.number = 2;
}
