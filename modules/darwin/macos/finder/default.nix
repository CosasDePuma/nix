{ config, options, lib, namespace, ... }: {
  options.${namespace}.macos.finder = {
    automanaged = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to automatically manage Finder settings.";
    };
  };

  config.system.defaults.finder = lib.mkIf config.${namespace}.macos.finder.automanaged {
    # Desktop
    CreateDesktop = lib.mkDefault false;                  # Don't show desktop icons
    ShowExternalHardDrivesOnDesktop = lib.mkDefault true; # Show external hard drives on desktop
    ShowHardDrivesOnDesktop = lib.mkDefault true;         # Show hard drives on desktop
    ShowMountedServersOnDesktop = lib.mkDefault true;     # Show mounted servers on desktop
    ShowRemovableMediaOnDesktop = lib.mkDefault true;     # Show removable media on desktop

    # Finder
    _FXSortFoldersFirst = lib.mkDefault true;             # Sort folders first
    AppleShowAllExtensions = lib.mkDefault true;          # Show all file extensions
    AppleShowAllFiles = lib.mkDefault true;               # Show hidden files
    FXPreferredViewStyle = lib.mkDefault "clmv";          # Column view
    NewWindowTarget = lib.mkDefault "Home";               # Show home folder when opening new Finder window
    QuitMenuItem = lib.mkDefault true;                    # Enable quit menu item
    ShowPathbar = lib.mkDefault true;                     # Show path breadcrumbs
    ShowStatusBar = lib.mkDefault true;                   # Show status bar at bottom of Finder
  };
}