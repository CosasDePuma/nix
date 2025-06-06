{
  pkgs ? import <nixpkgs> { },
  ...
}:
pkgs.mkShell {
  name = "nixos";

  buildInputs = with pkgs; [
    # --- nix checkers
    deadnix
    statix
    # --- nix formatters
    nixfmt-tree
  ];
}
