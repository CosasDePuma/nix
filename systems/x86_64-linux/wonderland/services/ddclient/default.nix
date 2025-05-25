_: {
  services.ddclient = {
    enable = true;                                    # Enable the ddclient service
    domains = [ "kike.wtf" ];                         # Domains to update
    interval = "1h";                                  # Update frequency
    protocol = "cloudflare";                          # Protocol to use
    passwordFile = "/run/agenix/ddclient-token";      # File containing provider API token
    verbose = true;                                   # Enable verbose output
    zone = "kike.wtf";                                # Zone to update
  };
}