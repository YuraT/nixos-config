{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules
  ];

  programs.plasma.kwin.virtualDesktops.number = 2;
}
