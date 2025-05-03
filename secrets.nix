let
  # users
  audea     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9Dt0O0OJokuV6x1jcejmHvJiGT8ZEubd5/aHGYEyUi audea";
  # systems
  vm-ecorp  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSuEfxFyY4TBNS6+pQVAVVZ/bVoBUaN68uJv7EooFuz @e-corp";
in {
  # e-corp
  "systems/x86_64-linux/e-corp/secrets/acme-token.age".publicKeys    = [ audea vm-ecorp ];
  "systems/x86_64-linux/e-corp/secrets/duckdns-token.age".publicKeys = [ audea vm-ecorp ];
}