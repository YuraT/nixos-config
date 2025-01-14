{ ... }:

{
#  boot.kernelParams = [ "console=tty0" ];
  proxmox.qemuConf.bios = "ovmf";
  proxmox.qemuExtraConf = {
    machine = "q35";
#    efidisk0 = "local-lvm:vm-9999-disk-1";
    cpu = "host";
  };
}
