{ pkgs, ... }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [
    hashcat
    metasploit
    nmap
    openvpn
    rockyou
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
      echo "hashcat            |> hash cracking"
      echo "hydra              |> brute-force attack"
      echo "nmap               |> network scanner"
      echo "openvpn            |> openvpn client"
      echo "msfconsole         |> exploit framework"
      echo "ssh-audit          |> ssh configuration checks"
      echo " + rockyou"
      echo
    }
    clear && help
  '';
}
