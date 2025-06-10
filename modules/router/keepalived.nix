{ config, lib, pkgs, ... }:
let
  vaks = import ./vaks.nix config;
in
{
  services.keepalived = {
    enable = true;

  };
}
