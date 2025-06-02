{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.opts.kb-input;
in {
  options = {
    opts.kb-input = {
      enable = lib.mkEnableOption "input method and custom keyboard layout";
      enableMinimak = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Minimak keyboard layout";
      };
      enableFcitx = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Fcitx5 input method";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkb.extraLayouts = lib.mkIf cfg.enableMinimak {
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

    i18n.inputMethod = lib.mkIf cfg.enableFcitx {
      enable = true;
      type = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.plasma6Support = true;
      fcitx5.addons = [ pkgs.fcitx5-mozc ];
    };
  };
}
