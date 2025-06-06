{ config, lib, pkgs, ... }:
{
  imports = [
    ./modules/starship.nix
    ./modules/plasma.nix
  ];

  services.darkman = {
    enable = true;
    settings = {
      lat = 37.3387;
      lng = -121.8853;
    };
    lightModeScripts = {
      plasma-color = "plasma-apply-colorscheme BreezeLight";
    };
    darkModeScripts = {
      plasma-color = "plasma-apply-colorscheme BreezeDark";
    };
  };
}
