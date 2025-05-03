{ config, options, lib, namespace, inputs, ... }:
  lib.optionalAttrs (builtins.hasAttr "disko" inputs) {
    imports = [ inputs.disko.nixosModules.default ];

    options."${namespace}".disko = {
      disk = lib.mkOption {
        type = lib.types.path;
        default = "/dev/disk/by-diskseq/1";
        description = "The device to install NixOS on.";
      };
    };

    config = {
      # Boot
      boot.readOnlyNixStore = lib.mkDefault true;
      boot.supportedFilesystems = lib.mkForce [ "btrfs" ];
      boot.loader.grub.enable = lib.mkDefault true;
      boot.loader.grub.efiSupport = lib.mkDefault true;
      boot.loader.grub.efiInstallAsRemovable = lib.mkDefault true;
      hardware.enableAllHardware = lib.mkDefault true;

      # Disk
      disko.devices = {
        disk."main" = {
          device = config."${namespace}".disko.disk;
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
            };

            content.subvolumes."@nix" = {
              mountpoint = "/nix";
              mountOptions = [ "compress=zstd" "noatime" ];
            };

            content.subvolumes."@home" = {
              mountpoint = "/home";
              mountOptions = [ "compress=zstd" "noatime" ];
            };

            content.subvolumes."@logs" = {
              mountpoint = "/var/log";
              mountOptions = [ "compress=zstd" "noatime" ];
            };

            content.subvolumes."@persistent" = {
              mountpoint = "/persistent";
              mountOptions = [ "compress=zstd" "noatime" ];
            };
          };
        };
        nodev."/tmp" = {
          fsType = "tmpfs";
          mountOptions = [ "size=200M" ];
        };
      };
    };
  }