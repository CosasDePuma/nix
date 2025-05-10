{ config, options, lib, pkgs, namespace, inputs, ... }: let cfg = config."${namespace}".disko; in
  lib.optionalAttrs (builtins.hasAttr "disko" inputs) {
    imports = [ inputs.disko.nixosModules.default inputs.impermanence.nixosModules.default ];

    # +----------------------------------------------------------------------------+
    # |                                  Options                                   |
    # +----------------------------------------------------------------------------+
    
    options."${namespace}".disko = {
      devices = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        default = [];
        example = [ "/dev/disk/by-diskseq/1" ];
        description = "The devices to install NixOS on.";
      };

      zfsMode = lib.mkOption {
        type = lib.types.enum [ "single" "mirror" "raidz" "raidz1" "raidz2" "raidz3" ];
        default = "single";
        example = "mirror";
        description = "The ZFS mode to use for the pool";
      };

      impermanence = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Whether to use impermanence for the root filesystem.";
      };
    };

    # +----------------------------------------------------------------------------+
    # |                                   Config                                   |
    # +----------------------------------------------------------------------------+

    config = lib.mkIf (builtins.length cfg.devices != 0) {
  
      # =================================== Boot ===================================

      boot.readOnlyNixStore = lib.mkDefault true;
      boot.supportedFilesystems = lib.mkForce [ "zfs" ];
      boot.loader.grub.enable = lib.mkDefault true;
      boot.loader.grub.efiSupport = lib.mkDefault true;
      boot.loader.grub.efiInstallAsRemovable = lib.mkDefault true;
      hardware.enableAllHardware = lib.mkDefault true;
      networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);

      # =================================== Disk ===================================

      disko.devices = {
        disk = let
          mkZFS = i: {
            name = lib.mkDefault "NIX${builtins.toString i}S";
            size = lib.mkDefault "100%";
            content = { type = "zfs"; pool = lib.mkDefault "rpool"; };
          };
        in {
          
          # ------------------------------ Main disk -------------------------------
        
          "disk0" = {
            device  = lib.mkDefault (builtins.head cfg.devices);
            type    = lib.mkDefault "disk";
            content = {
              type = "gpt";

              # --- boot partition ---

              partitions."boot" = {
                name = lib.mkDefault "BOOT";
                size = lib.mkDefault "1M";
                type = lib.mkDefault "EF02";
              };

              # --- esp partition ---

              partitions."esp" = {
                name = lib.mkDefault "ESP";
                size = lib.mkDefault "500M";
                type = lib.mkDefault "EF00";
                content = {
                  type       = "filesystem";
                  format     = lib.mkDefault "vfat";
                  mountpoint = lib.mkDefault "/boot";
                  extraArgs  = lib.mkDefault [ "-n" "ESP" ];
                };
              };

              # --- root partition ---

              partitions."root" = mkZFS 0;
            };
          } // builtins.listToAttrs (lib.lists.imap1 (i: v: {
            "disk${builtins.toString i}" = { 
              device  = lib.mkDefault v;
              type    = lib.mkDefault "disk";
              content = { 
                type = "gpt";
                partitions."zfs" = mkZFS i; 
              };
            };
          }) (builtins.tail cfg.devices));
        };

        # -------------------------------- ZFS Pool --------------------------------

        zpool."rpool" = {
          type        = lib.mkDefault "zpool";
          mode        = lib.mkDefault (if cfg.zfsMode == "single" then "" else cfg.zfsMode);
          mountpoint  = lib.mkDefault "/";
          options = {
            ashift    = lib.mkDefault "12";
            autotrim  = lib.mkDefault "on";
            cachefile = lib.mkDefault "none";
          };
          rootFsOptions = {
            acltype       = lib.mkDefault "posixacl";
            canmount      = lib.mkDefault "off";
            compression   = lib.mkDefault "zstd";
            dnodesize     = lib.mkDefault "auto";
            normalization = lib.mkDefault "formD";
            relatime      = lib.mkDefault "on";
            xattr         = lib.mkDefault "sa";
            "com.sun:auto-snapshot" = lib.mkDefault "false";
          };

          datasets = lib.mkMerge [
            {
              "nixos" = {
                type               = "zfs_fs";
                options.canmount   = lib.mkDefault "off";
              };
              "nixos/root" = {
                type               = "zfs_fs";
                mountpoint         = lib.mkDefault "/";
                mountOptions       = lib.mkDefault [ "noexec" ];
                options.mountpoint = lib.mkDefault "legacy";
                postCreateHook     = lib.mkDefault "zfs list -t snapshot -H -o name | grep -E '^rpool/nixos/root@blank$' || zfs snapshot rpool/nixos/root@blank";
              };
              "nixos/nix" = {
                type               = "zfs_fs";
                mountpoint         = lib.mkDefault "/nix";
                mountOptions       = lib.mkDefault [ "defaults" ];
                options.mountpoint = lib.mkDefault "legacy";
              };
              "nixos/logs" = {
                type               = "zfs_fs";
                mountpoint         = lib.mkDefault "/var/log";
                mountOptions       = lib.mkDefault [ "noexec" ];
                options.mountpoint = lib.mkDefault "legacy";
              };
            }
            (lib.mkIf cfg.impermanence {
              "nixos/persist" = {
                type               = "zfs_fs";
                mountpoint         = lib.mkDefault "/nix/persist";
                mountOptions       = lib.mkDefault [ "noexec" ];
                options.mountpoint = lib.mkDefault "legacy";
              };
            })
          ];
        };

        # --------------------------------- TmpFS ----------------------------------

        nodev."/tmp" = {
          fsType       = lib.mkDefault "tmpfs";
          mountOptions = lib.mkDefault [ "noexec" "size=200M" ];
        };
      };

      # ================================ FileSystem ================================

      fileSystems = lib.mkMerge [
        {
          "/" = {
            device        = lib.mkDefault "rpool/nixos/root";
            fsType        = lib.mkDefault "zfs";
          };
          "/nix" = {
            device        = lib.mkDefault "rpool/nixos/nix";
            fsType        = lib.mkDefault "zfs";
            neededForBoot = lib.mkDefault true;
          };
          "/var/log" = {
            device        = lib.mkDefault "rpool/nixos/logs";
            fsType        = lib.mkDefault "zfs";
          };
        }
        (lib.mkIf cfg.impermanence {
          "/nix/persist" = {
            device        = lib.mkDefault "rpool/nixos/persist";
            fsType        = lib.mkDefault "zfs";
            neededForBoot = lib.mkDefault cfg.impermanence;
          };
        })
      ];

      # =============================== Impermanence ===============================

      boot.initrd.systemd = lib.mkIf cfg.impermanence { 
        enable = lib.mkDefault true;
        services."zfs-rollback" = {
          after       = lib.mkDefault [ "zfs-import-rpool.service" ];
          wantedBy    = lib.mkDefault [ "initrd.target" ];
          before      = lib.mkDefault [ "sysroot.mount" ];
          path        = lib.mkDefault [ pkgs.zfs ];
          script      = lib.mkDefault "${pkgs.zfs}/bin/zfs rollback -r rpool/nixos/root@blank";
          description = lib.mkDefault "Rollback ZFS root filesystem to blank snapshot";
          serviceConfig.Type = lib.mkDefault "oneshot";
          unitConfig.DefaultDependencies = lib.mkDefault "no";
        };
      };

      environment.persistence = lib.mkIf cfg.impermanence {
        "/nix/persist/.system" = {
          enable = lib.mkDefault true;
          hideMounts = lib.mkDefault true;
          directories = [ "/var/lib/nixos" ];
          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
          ];
        };
      };
    };
  }