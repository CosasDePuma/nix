{
  config ? throw "no imported as a module",
  lib ? throw "not imported as a module",
  device ? "device not defined",
  ...
}:
lib.mkIf (config ? "disko") {
  disko.devices = {

    # ============================= Disks ==============================

    disk = {
      "disk0" = {
        inherit device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {

            # --- boot partition ---
            "BOOT" = {
              size = "1M";
              type = "EF02";
            };

            # --- uefi partition ---
            "ESP" = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                extraArgs = [
                  "-n"
                  "ESP"
                ];
              };
            };

            # --- filesystem partition ---
            "NIXOS" = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [
                  "-L"
                  "NIXOS"
                ];
              };
            };
          };
        };
      };
    };

    # =========================== No Devices ===========================

    nodev = {
      # --- tmpfs for /tmp ---
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [
          "noexec"
          "size=1G"
        ];
      };
    };
  };
}
