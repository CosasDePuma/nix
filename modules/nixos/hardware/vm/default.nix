{ config, options, lib, namespace, ... }: {
  options."${namespace}".hardware.isVM = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether the hardware is a virtual machine or not.";
  };

  config = lib.mkIf config."${namespace}".hardware.isVM {
    # Services
    services.qemuGuest.enable = lib.mkDefault true;
    services.spice-vdagentd.enable = lib.mkDefault true;
  };
}