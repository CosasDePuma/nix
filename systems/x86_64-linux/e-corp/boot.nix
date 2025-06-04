_: _: {
  boot.loader.grub = {
    enable = true;                 # Enable GRUB bootloader
    efiSupport = true;             # Enable UEFI support
    efiInstallAsRemovable = true;  # Install EFI as removable device
  };
}