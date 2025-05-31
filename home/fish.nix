{ config, lib, pkgs, ... }:

{
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
}
