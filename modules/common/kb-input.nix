{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.common.kb-input;
in {
  options = {
    common.kb-input = {
      enable = lib.mkEnableOption "input method and custom keyboard layout";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkb.extraLayouts = {
      minimak-4 = {
        description = "English (US, Minimak-4)";
        languages = [ "eng" ];
        symbolsFile = ./minimak;
      };
      minimak-8 = {
        description = "English (US, Minimak-8)";
        languages = [ "eng" ];
        symbolsFile = ./minimak;
      };
      minimak-12 = {
        description = "English (US, Minimak-12)";
        languages = [ "eng" ];
        symbolsFile = ./minimak;
      };
    };

    i18n.inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.waylandFrontend = true;
      fcitx5.plasma6Support = true;
      fcitx5.addons = [ pkgs.fcitx5-mozc ];
    };
  };
}