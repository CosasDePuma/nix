{ pkgs, inputs, system, ... }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [
    metasploit
    nmap
    ssh-audit
    thc-hydra
  ];
  shellHook = ''
    help() {
      echo 
      echo "+--------------------+"
      echo "| Available commands |"
      echo "+--------------------+"
      echo
      echo "hydra              |> brute-force attack"
      echo "nmap               |> network scanner"
      echo "msfconsole         |> exploit framework"
      echo "ssh-audit          |> ssh configuration checks"
      echo
    }
    clear && help
  '';
}
