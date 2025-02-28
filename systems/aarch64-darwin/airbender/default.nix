{ namespace, ... }: {
  ids.gids.nixbld = 350;

  "${namespace}" = {
    # i18n
    i18n.timezone = "Europe/Madrid";

    # MacOS
    security.touchID.enable = true;
    macos.finder.automanaged = true;
    macos.homebrew.enable = true;
    macos.homebrew.storeApps = { "wireguard" = 1451685025; };
    macos.homebrew.casks = let appsDir = "/Applications/Homebrew"; in [
      # Artificial Intelligence
      { name = "ollama";             args = { appdir = "${appsDir}/Artificial Intelligence"; }; }
      { name = "lm-studio";          args = { appdir = "${appsDir}/Artificial Intelligence"; }; }
      # Communication
      { name = "discord";            args = { appdir = "${appsDir}/Communication"; }; }
      { name = "telegram";           args = { appdir = "${appsDir}/Communication"; }; }
      { name = "whatsapp";           args = { appdir = "${appsDir}/Communication"; }; }
      # Development
      { name = "visual-studio-code"; args = { appdir = "${appsDir}/Development"; }; }
      { name = "warp";               args = { appdir = "${appsDir}/Development"; }; }
      # Entertainment
      { name = "spotify";            args = { appdir = "${appsDir}/Entertainment"; }; }
      { name = "steam";              args = { appdir = "${appsDir}/Entertainment"; }; }
      # HomeLab
      { name = "bitwarden";          args = { appdir = "${appsDir}/HomeLab"; }; }
      # Utilities
      { name = "cleanmymac";         args = { appdir = "${appsDir}/Utilities"; }; }
      { name = "the-unarchiver";     args = { appdir = "${appsDir}/Utilities"; }; }
    ];

    # Nix-Darwin
    nixos.version = 6;
  };
}