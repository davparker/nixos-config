{ config, pkgs, ... }:

{
  # Tailscale client service
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both"; # Configures routing for subnet router & exit node features
  };

  # Kernel parameters for subnet routing & network throughput optimization
  boot.kernel.sysctl = {
    # IP forwarding required for subnet routers / exit nodes
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # Maximum buffer size limits (up to 16MB)
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;

    # Default socket buffer sizes (up to 1MB)
    "net.core.rmem_default" = 1048576;
    "net.core.wmem_default" = 1048576;

    # Maximum backlog of queued incoming packets
    "net.core.netdev_max_backlog" = 10000;
  };

  # Firewall rules for Tailscale traffic
  networking.firewall = {
    # Allow Tailscale communication port
    allowedUDPPorts = [ config.services.tailscale.port ];

    # Trust the virtual Tailscale interface
    trustedInterfaces = [ "tailscale0" ];

    # Loose reverse path filtering avoids dropped packets when routing traffic
    checkReversePath = "loose";
  };
}
