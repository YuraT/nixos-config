{ config, lib, pkgs, ... }:
let
  username = "cazzzer";
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "micro";
    SHELL = "fish";
  };

  # TODO: remove (replace by bitwarden-desktop)
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "ssh" ];
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

  programs.fish = {
    enable = true;
    shellInit = "set fish_greeting";
    shellAliases = {
      # Replace ls with exa
      ls = "exa -al --color=always --group-directories-first --icons"; # preferred listing
      la = "exa -a --color=always --group-directories-first --icons";  # all files and dirs
      ll = "exa -l --color=always --group-directories-first --icons";  # long format
      lt = "exa -aT --color=always --group-directories-first --icons"; # tree listing
      "l." = "exa -a | rg '^\.'";                                      # show only dotfiles

      # Replace cat with bat
      cat = "bat";
    };
    # alias for nix shell with flake packages
    functions.add.body = ''
      set -x packages 'nixpkgs#'$argv
      nix shell $packages
    '';
    interactiveShellInit = ''
      fastfetch
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$all"
        "$time"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$status"
        "$character"
      ];
      username = {
        format = " [╭─$user]($style)@";
        style_user = "bold red";
        style_root = "bold red";
        show_always = true;
      };
      hostname = {
        format = "[$hostname]($style) in ";
        style = "bold dimmed red";
        ssh_only = false;
      };
      directory = {
        style = "purple";
        truncation_length = 0;
        truncate_to_repo = true;
        truncation_symbol = "repo: ";
      };
      git_status = {
        style = "white";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        deleted = "x";
      };
      cmd_duration = {
        min_time = 1000;
        format = "took [$duration]($style) ";
      };
      time = {
        format = " 🕙 $time($style) ";
        time_format = "%T";
        style = "bright-white";
        disabled = false;
      };
      character = {
        success_symbol = " [╰─λ](bold red)";
        error_symbol = " [×](bold red)";
      };
      status = {
        symbol = "🔴";
        format = "[\\[$symbol$status_common_meaning$status_signal_name$status_maybe_int\\]]($style)";
        map_symbol = true;
        disabled = false;
      };
    };
  };

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    # TODO: figure out how to enable tela-circle icon theme if installed in systemPackages
    # workspace.iconTheme = if builtins.elem pkgs.tela-circle-icon-theme config.environment.systemPackages then "Tela-circle" else null;
    workspace.iconTheme = "Tela-circle";
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
