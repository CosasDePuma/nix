{
  pkgs,
  inputs,
  system,
  ...
}:
with pkgs;
mkShell {
  name = "hacking-infra";
  buildInputs = [
    metasploit # penetration testing framework
    nmap # port scanner
    nuclei
    ssh-audit # ssh auditing tool
    terrapin-scanner # cve-2023-48795
  ];
}
