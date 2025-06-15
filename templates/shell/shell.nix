{
  pkgs,
  ...
}:
pkgs.mkShell {
  name = "shell";

  buildInputs = with pkgs; [ ];

  shellHook = '''';
}
