{ config, lib, pkgs, ... }:
let
  name = "Yuri Tatishchev";
  email = "itatishch@gmail.com";
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE02AhJIZtrtZ+5sZhna39LUUCEojQzmz2BDWguT9ZHG";
in
{
  programs.git = {
    enable = true;

    userName = name;
    userEmail = email;

    signing = {
      key = signingKey;
      signByDefault = true;
      format = "ssh";
    };

    aliases = {
      co = "checkout";
      s = "switch";
    };

    extraConfig = {
      url = {
        "https://gitea.cazzzer.com/" = {
          insteadOf = "caztea:";
        };
        "https://github.com/" = {
          insteadOf = "github:";
        };
      };

      core = {
        autocrlf = "input";
        editor = "micro";
      };

      color = {
        ui = true;
      };

      pull = {
        ff = "only";
      };

      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      credential = {
        helper = "libsecret";
      };

      merge = {
        conflictStyle = "zdiff3";
      };
    };
  };
}
