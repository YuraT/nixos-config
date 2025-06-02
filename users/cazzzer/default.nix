{ config, lib, pkgs, ... }: {
  users.groups.cazzzer.gid = 1000;
  users.users.cazzzer = {
    uid = 1000;
    isNormalUser = true;
    description = "Yura";
    group = "cazzzer";
    extraGroups = [ "wheel" ]
      ++ lib.optionals config.networking.networkmanager.enable [ "networkmanager" ]
      ++ lib.optionals config.virtualisation.docker.enable [ "docker" ]
      ++ lib.optionals config.programs.wireshark.enable [ "wireshark" ]
    ;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE02AhJIZtrtZ+5sZhna39LUUCEojQzmz2BDWguT9ZHG yuri@tati.sh"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHczlipzGWv8c6oYwt2/9ykes5ElfneywDXBTOYbfSfn Pixel7Pro"
    ];
  };
}
