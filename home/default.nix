{ config, pkgs, ... }:
let
  defaultFont = {
    family = "Noto Sans";
    pointSize = 13;
  };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cazzzer";
  home.homeDirectory = "/home/cazzzer";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "micro";
    SHELL = "fish";
  };

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

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace.iconTheme = "Tela-circle";
    fonts = {
      general = defaultFont;
      fixedWidth = defaultFont // { family = "Hack"; };
      small = defaultFont // { pointSize = defaultFont.pointSize - 2; };
      toolbar = defaultFont;
      menu = defaultFont;
      windowTitle = defaultFont;
    };
    input.keyboard.layouts = [ { layout = "minimak-4"; displayName = "us4"; } ];
    kwin.virtualDesktops.number = 2;
    shortcuts = {
      # kmix.mic_mute = "ScrollLock";
      kmix.mic_mute = ["Microphone Mute" "ScrollLock" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone"];
      plasmashell.show-barcode = "Meta+M";
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
      kactivitymanagerdrc = {
        activities."809dc779-bf5b-49e6-8e3f-cbe283cb05b6" = "Default";
        activities."b34a506d-ac4f-4797-8c08-6ef45bc49341" = "Fun";
        activities-icons."809dc779-bf5b-49e6-8e3f-cbe283cb05b6" = "keyboard";
        activities-icons."b34a506d-ac4f-4797-8c08-6ef45bc49341" = "preferences-desktop-gaming";
      };
    };
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  # home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  # ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  # home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  # };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cazzzer/etc/profile.d/hm-session-vars.sh
  #
  # home.sessionVariables = {
    # EDITOR = "emacs";
  # };
}
