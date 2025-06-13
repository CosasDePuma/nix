{
  pkgs,
  inputs,
  system,
  ...
}:
with pkgs;
mkShell {
  name = "nixos";
  NIX_CONFIG = "experimental-features = flakes nix-command pipe-operators";
  buildInputs = [
    deadnix # dead code scanner
    nh # yet another nix cli wrapper
    nixfmt-tree # nix formatter
    nixos-anywhere # nixos installation over ssh
    nixos-rebuild # nixos configuration rebuild
    statix # nixos configuration linter

    inputs.agenix.packages.${system}.default # secret management
  ];
}
