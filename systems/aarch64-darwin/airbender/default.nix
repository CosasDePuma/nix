_: {
  # +-----------------------------------------------------------------------------+
  # |                                 Nix Daemon                                  |
  # +-----------------------------------------------------------------------------+
  
  # Configures the Nix daemon for Darwin.
  # Allows for the system to be managed by Nix.

  ids.gids.nixbld = 350;                               # Nix build group ID
  system.stateVersion = 6;                             # Nix Darwin version

  # +-----------------------------------------------------------------------------+
  # |                                Localization                                 |
  # +-----------------------------------------------------------------------------+

  # Configures the system's zone to ensure correct local time and language.
  
  time.timeZone = "Europe/Madrid";                     # System timezone

  # +-----------------------------------------------------------------------------+
  # |                                  Security                                   |
  # +-----------------------------------------------------------------------------+

  # Configures the system's security settings. Implements the following options:
  # - TouchID authentication for sudo.

  security.pam.services.sudo_local.touchIdAuth = true; # Enable TouchID authentication for sudo

  # +-----------------------------------------------------------------------------+
  # |                                  Software                                   |
  # +-----------------------------------------------------------------------------+

  # Installs the required software. Installations are done via Homebrew by default.
  # Software is organized into folders for easier management.

  homebrew = {
    enable = true;
    global = { autoUpdate = true; brewfile = true; };  # Auto-updates via fixed Brewfile
    onActivation = {
      autoUpdate = true;                               # Auto-updates when switching to this configuration
      cleanup = "zap";                                 # Cleanup when switching to this configuration
    };
    masApps = {                                        # App Store apps:
      "cleanmymac" = 1339170533;                       # - System cleaner
      "steamlink"  = 1246969117;                       # - Remote control streaming for Steam
      "wireguard"  = 1451685025;                       # - VPN client
    };
    casks = let
      appsDir = "/Applications/Homebrew";              # Default apps directory
      organize = folder: apps: builtins.map (name: { inherit name; args = { appdir = "${appsDir}/${folder}"; }; }) apps;
    in builtins.concatLists [
      (organize "Artificial Intelligence" [ "ollama" "lm-studio" ])
      (organize "Communication"           [ "discord" "telegram" "whatsapp" ])
      (organize "Development"             [ "trae" "warp" ])
      (organize "Entertainment"           [ "spotify" "steam" ])
      (organize "HomeLab"                 [ "bitwarden" ])
      (organize "Utilities"               [ "brave-browser" "flameshot" "the-unarchiver" "vlc" "webtorrent" ])
    ];
  };

  # +-----------------------------------------------------------------------------+
  # |                                   Finder                                    |
  # +-----------------------------------------------------------------------------+

  # Configures the Finder's settings. Implements the following options:
  # - Desktop:
  #   - Show external hard drives on desktop.
  #   - Show hard drives on desktop.
  #   - Show mounted servers on desktop.
  #   - Show removable media on desktop.
  # - Finder:
  #   - Sort folders first.
  #   - Show all file extensions.
  #   - Show hidden files.
  #   - Show path breadcrumbs.
  #   - Show status bar at bottom of Finder.
  #   - Show home folder when opening new Finder window.
  #   - Enable quit Finder.
  #   - Set the column view as default.

  system.defaults.finder = {
    # Desktop
    CreateDesktop = false;                             # Don't show desktop icons
    ShowExternalHardDrivesOnDesktop = true;            # Show external hard drives on desktop
    ShowHardDrivesOnDesktop = true;                    # Show hard drives on desktop
    ShowMountedServersOnDesktop = true;                # Show mounted servers on desktop
    ShowRemovableMediaOnDesktop = true;                # Show removable media on desktop

    # Finder
    _FXSortFoldersFirst = true;                        # Sort folders first
    AppleShowAllExtensions = true;                     # Show all file extensions
    AppleShowAllFiles = true;                          # Show hidden files
    FXPreferredViewStyle = "clmv";                     # Column view
    NewWindowTarget = "Home";                          # Show home folder when opening new Finder window
    QuitMenuItem = true;                               # Enable quit menu item
    ShowPathbar = true;                                # Show path breadcrumbs
    ShowStatusBar = true;                              # Show status bar at bottom of Finder
  };


  # +-----------------------------------------------------------------------------+
  # |                                   System                                    |
  # +-----------------------------------------------------------------------------+

  # Configures the system's settings for maximum compatibility with Nix on common
  # architectures. Also allows unfree packages.

  nix = {
    enable = false;
    extraOptions = "extra-platforms = x86_64-darwin aarch64-darwin";
    settings.auto-optimise-store = false;  # https://github.com/NixOS/nix/issues/7273
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  nixpkgs.config.allowUnfree = true;
}