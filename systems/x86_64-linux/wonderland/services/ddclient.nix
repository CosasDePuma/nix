{ dnsProvider, domain, ... }: _: {
  services.ddclient = {
    enable = true;                                 # Enable the ddclient service
    domains = [ domain ];                          # Domains to update
    interval = "1h";                               # Update frequency
    protocol = dnsProvider;                        # Protocol to use
    passwordFile = "/run/agenix/ddclient-token";   # File containing provider API token
    verbose = true;                                # Enable verbose output
    zone = domain;                                # Zone to update
  };
}