{ namespace, ... }: {
  ids.gids.nixbld = 350;

  "${namespace}" = {
    # i18n
    i18n.timezone = "Europe/Madrid";

    # MacOS
    security.touchID.enable = true;
    macos.finder.automanaged = true;
    macos.homebrew.enable = true;
    macos.homebrew.storeApps = { "cleanmymac" = 1339170533; "steamlink" = 1246969117; "wireguard" = 1451685025; };
    macos.homebrew.casks = let
        appsDir = "/Applications/Homebrew";
        organize = folder: apps: builtins.map (name: { inherit name; args = { appdir = "${appsDir}/${folder}"; }; }) apps;
      in builtins.concatLists [
        (organize "Artificial Intelligence" [ "ollama" "lm-studio" ])
        (organize "Communication"           [ "discord" "telegram" "whatsapp" ])
        (organize "Development"             [ "trae" "warp" ])
        (organize "Entertainment"           [ "spotify" "steam" ])
        (organize "HomeLab"                 [ "bitwarden" ])
        (organize "Utilities"               [ "brave-browser" "the-unarchiver" "vlc" "webtorrent" ])
      ];
    
    # Networking
    networking.hostName = "airbender";

    # Nix-Darwin
    nixos.version = 6;
  };
}