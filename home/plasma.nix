{ config, lib, pkgs, osConfig, ... }:

{
  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace.iconTheme = if builtins.elem pkgs.tela-circle-icon-theme osConfig.environment.systemPackages then "Tela-circle" else null;
    fonts = let
      defaultFont = {
        family = "Noto Sans";
        pointSize = 14;
      };
    in {
      general = defaultFont;
      fixedWidth = defaultFont // { family = "Hack"; };
      small = defaultFont // { pointSize = defaultFont.pointSize - 2; };
      toolbar = defaultFont;
      menu = defaultFont;
      windowTitle = defaultFont;
    };
    input.keyboard.layouts = [
      { layout = "us"; displayName = "us"; }
      { layout = "minimak-4"; displayName = "us4"; }
      { layout = "ru"; displayName = "ru"; }
    ];
    kwin.virtualDesktops.number = 2;
    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    shortcuts = {
      # kmix.mic_mute = "ScrollLock";
      kmix.mic_mute = ["Microphone Mute" "ScrollLock" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone"];
      plasmashell.show-barcode = "Meta+M";
      kwin."Window Maximize" = [ "Meta+F" "Meta+PgUp,Maximize Window" ];
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Space";
    };
    hotkeys.commands."launch-konsole" = {
      name = "Launch Konsole";
      key = "Meta+Alt+C";
      command = "konsole";
    };
    configFile = {
      kdeglobals.KDE.AnimationDurationFactor = 0.5;
      kdeglobals.General.accentColorFromWallpaper = true;
      kwinrc.Wayland.InputMethod = {
        value = "org.fcitx.Fcitx5.desktop";
        shellExpand = true;
      };
      dolphinrc.General.ShowFullPath = true;
      dolphinrc.DetailsMode.PreviewSize.persistent = true;
      kactivitymanagerdrc = {
        activities."809dc779-bf5b-49e6-8e3f-cbe283cb05b6" = "Default";
        activities."b34a506d-ac4f-4797-8c08-6ef45bc49341" = "Fun";
        activities-icons."809dc779-bf5b-49e6-8e3f-cbe283cb05b6" = "keyboard";
        activities-icons."b34a506d-ac4f-4797-8c08-6ef45bc49341" = "preferences-desktop-gaming";
      };
    };
  };

  xdg.configFile = {
    "fcitx5/conf/wayland.conf".text = "Allow Overriding System XKB Settings=False";
  };
}
