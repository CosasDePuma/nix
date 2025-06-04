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
          content.type = "btrfs";
          content.extraArgs = [ "-L" "NIXOS" "-f" ];

          content.subvolumes."@root" = {
            mountpoint = "/";
            mountOptions = [ "noatime" "noexec" ];
          };

          content.subvolumes."@nix" = {
            mountpoint = "/nix";
            mountOptions = [ "compress=zstd" "noatime" ];
          };

          content.subvolumes."@persistent" = {
            mountpoint = safeDir;
            mountOptions = [ "compress=zstd" "noatime" "noexec" ];
          };
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