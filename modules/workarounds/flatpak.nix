# https://github.com/knightpp/nixos-cfg/blob/main/modules/workarounds/flatpak.nix
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.workarounds.flatpak;
in {
  options = {
    workarounds.flatpak = {
      enable = lib.mkEnableOption "flatpak workaround";
    };
  };

  config = lib.mkIf cfg.enable {
    system.fsPackages = [pkgs.bindfs];
    fileSystems = let
      mkRoSymBind = path: {
        device = path;
        fsType = "fuse.bindfs";
        options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
      };
      aggregated = pkgs.buildEnv {
        name = "system-fonts-and-icons";
        paths = builtins.attrValues {
          inherit (pkgs.kdePackages) breeze;
          inherit
            (pkgs)
            noto-fonts
            noto-fonts-emoji
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            ;
        };
        pathsToLink = ["/share/fonts" "/share/icons"];
      };
    in {
      # Create an FHS mount to support flatpak host icons/fonts
      "/usr/share/icons" = mkRoSymBind "${aggregated}/share/icons";
      "/usr/share/fonts" = mkRoSymBind "${aggregated}/share/fonts";
    };
  };
}
