{ pkgs, ... }: with pkgs; mkShell {
  buildInputs = [ ];
  shellHook = ''
    help() {
      echo 
      echo "+--------------------+"
      echo "| Available commands |"
      echo "+--------------------+"
      echo 
      echo "help               |> show this message"
      echo
    }
    clear && help
  '';
}