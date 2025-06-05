{ safeDir, ... }: { config, lib, inputs, ... }: let
  device = "/dev/nvme0n1";   # TODO(improvement): more than one disk support
in {
  imports = lib.lists.optional (inputs ? "disko") inputs.disko.nixosModules.default;
  config = lib.mkIf (inputs ? "disko") {
    boot.supportedFilesystems.btrfs = true;
    disko.devices = {

      # ============================= Disks ==============================

      disk."disk0" = {
        inherit device;
        type = "disk";
        content.type = "gpt";

        content.partitions."boot" = {
          name = "BOOT";
          size = "1M";
          type = "EF02";
        };

        content.partitions."esp" = {
          name = "ESP";
          size = "500M";
          type = "EF00";
          content.type = "filesystem";
          content.format = "vfat";
          content.mountpoint = "/boot";
          content.extraArgs = [ "-n" "ESP" ];
        };

        content.partitions."root" = {
          name = "NIXOS";
          size = "100%";
          content.type = "filesystem";
          content.format = "ext4";
          content.mountpoint = "/";
          content.extraArgs = [ "-L" "NIXOS" ];
        };
      };

      # =========================== No Devices ===========================

      nodev = {
        # --- tmpfs for /tmp ---
        "/tmp" = {
          fsType = "tmpfs";
          mountOptions = [ "noexec" "size=200M" ];
        };
      };
    };
  };
}