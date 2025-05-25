{ config, lib, inputs, ... }: let
  device = "/dev/sda";
in {
  imports = lib.lists.optional (inputs ? "disko") inputs.disko.nixosModules.default;

  config = lib.mkIf (inputs ? "disko") {
    disko.devices.disk = {
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
                type       = "filesystem";
                format     = "vfat";
                mountpoint = "/boot";
                extraArgs  = [ "-n" "ESP" ];
              };
            };

            # --- filesystem partition ---
            "NIXOS" = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}