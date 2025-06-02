{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules
  ];

  programs.plasma = {
    kwin.virtualDesktops.number = 6;
    kwin.virtualDesktops.rows = 2;

    shortcuts.kwin = {
      "Switch to Desktop 1" = "Meta+F1";
      "Switch to Desktop 2" = "Meta+F2";
      "Switch to Desktop 3" = "Meta+F3";
      "Switch to Desktop 4" = "Meta+Z";
      "Switch to Desktop 5" = "Meta+X";
      "Switch to Desktop 6" = "Meta+C";
    };
  };
}
