{
  pkgs ? import <nixpkgs> { },
  ...
}:
pkgs.mkShell {
  name = "default-shell";

  buildInputs = with pkgs; [ ];

  shellHook = '''';
}
