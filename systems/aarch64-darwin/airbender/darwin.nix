{
  user ? throw "user not defined",
  ...
}:
{
  # +-----------------------------------------------------------------------------+
  # |                                  Defaults                                   |
  # +-----------------------------------------------------------------------------+
  # Configures the default settings. Implements the following options:
  # - Desktop:
  #   - Show external hard drives on desktop.
  #   - Show hard drives on desktop.
  #   - Show mounted servers on desktop.
  #   - Show removable media on desktop.
  # - Dock:
  #   - Auto-hide.
  # - Finder:
  #   - Sort folders first.
  #   - Show all file extensions.
  #   - Show hidden files.
  #   - Show path breadcrumbs.
  #   - Show status bar at bottom of Finder.
  #   - Show home folder when opening new Finder window.
  #   - Enable quit Finder.
  #   - Set the column view as default.

  system.defaults = {
    # --- dock
    dock = {
      autohide = true; # Auto-hide the Dock
    };

    # --- finder
    finder = {

      # --- desktop
      CreateDesktop = false; # Don't show desktop icons
      ShowExternalHardDrivesOnDesktop = true; # Show external hard drives on desktop
      ShowHardDrivesOnDesktop = true; # Show hard drives on desktop
      ShowMountedServersOnDesktop = true; # Show mounted servers on desktop
      ShowRemovableMediaOnDesktop = true; # Show removable media on desktop

      # --- folder
      _FXSortFoldersFirst = true; # Sort folders first
      AppleShowAllExtensions = true; # Show all file extensions
      AppleShowAllFiles = true; # Show hidden files
      FXPreferredViewStyle = "clmv"; # Column view
      NewWindowTarget = "Home"; # Show home folder when opening new Finder window
      QuitMenuItem = true; # Enable quit menu item
      ShowPathbar = true; # Show path breadcrumbs
      ShowStatusBar = true; # Show status bar at bottom of Finder
    };
  };

  # +-----------------------------------------------------------------------------+
  # |                                     Nix                                     |
  # +-----------------------------------------------------------------------------+
  # Configures the system's settings for maximum compatibility with Nix on common
  # architectures. Also allows unfree packages.

  ids.gids.nixbld = 350; # Nix build group ID
  nix = {
    enable = false;
    extraOptions = "extra-platforms = x86_64-darwin aarch64-darwin";
    settings.auto-optimise-store = false; # https://github.com/NixOS/nix/issues/7273
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  nixpkgs.config.allowUnfree = true;

  # +-----------------------------------------------------------------------------+
  # |                                   System                                    |
  # +-----------------------------------------------------------------------------+
  # Allows for the system to be managed by Nix.

  system = {
    stateVersion = 6; # Nix Darwin version
    primaryUser = user; # Primary user for the system
  };

  # +-----------------------------------------------------------------------------+
  # |                                Localization                                 |
  # +-----------------------------------------------------------------------------+
  # Configures the system's zone to ensure correct local time and language.

  time.timeZone = "Europe/Madrid"; # System timezone

  # +-----------------------------------------------------------------------------+
  # |                                  Security                                   |
  # +-----------------------------------------------------------------------------+
  # Configures the system's security settings. Implements the following options:
  # - TouchID authentication for sudo.

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # +-----------------------------------------------------------------------------+
  # |                                  Software                                   |
  # +-----------------------------------------------------------------------------+
  # Installs the required software. Installations are done via Homebrew by default.
  # Software is organized into folders for easier management.

  homebrew = {
    enable = true;
    global = {
      autoUpdate = true;
      brewfile = true;
    };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };

    # --- cli applications
    brews = [
      "bat"
      "direnv"
      "fish"
      "git"
      "lsd"
      "starship"
      "stow"
      "zoxide"
    ];

    # --- graphical applications
    casks =
      let
        appsDir = "/Applications/Homebrew"; # Default apps directory
        organize =
          folder: apps:
          builtins.map (name: {
            inherit name;
            args = {
              appdir = "${appsDir}/${folder}";
            };
          }) apps;
      in
      builtins.concatLists [
        (organize "Artificial Intelligence" [
          "claude"
          "ollama"
          "lm-studio"
        ])
        (organize "Communication" [
          "discord"
          "telegram"
          "whatsapp"
        ])
        (organize "Development" [
          "outerbase-studio"
          "visual-studio-code"
          "warp"
        ])
        (organize "Entertainment" [
          "spotify"
          "steam"
        ])
        (organize "Hacking" [
          "burp-suite"
          "cyberduck"
          "obsidian"
        ])
        (organize "HomeLab" [
          "bitwarden"
        ])
        (organize "Utilities" [
          "balenaetcher"
          "brave-browser"
          "flameshot"
          "font-fira-code-nerd-font"
          "font-jetbrains-mono-nerd-font"
          "the-unarchiver"
          "vlc"
          "webtorrent"
        ])
        (organize "Virtualization" [
          "orbstack"
          "utm"
          "whisky"
          "xquartz"
        ])
      ];

    # --- app store
    masApps = {
      "cleanmymac" = 1339170533;
      "steamlink" = 1246969117;
      "wireguard" = 1451685025;
    };
  };
}
