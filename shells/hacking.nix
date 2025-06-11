{
  pkgs,
  inputs,
  system,
  ...
}:
with pkgs;
mkShell {
  name = "hacking";
  buildInputs = [
    nmap
    python312Packages.impacket
    smbmap
  ];
}
