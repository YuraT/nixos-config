{ config, lib, pkgs, ... }:

{
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
}
