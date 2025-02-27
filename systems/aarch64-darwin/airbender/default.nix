{ namespace, ... }: {
  "${namespace}" = {
    # i18n
    i18n.timezone = "Europe/Madrid";

    # MacOS
    security.touchID.enable = true;

    # Nix-Darwin
    nixos.version = 6;
  };

  ids.gids.nixbld = 350;
}