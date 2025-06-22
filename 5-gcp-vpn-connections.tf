# GCP Network Infrastructure
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network

# GCP Network Infrastructure 
resource "google_compute_network" "main-vpc" {
  name                    = "main-vpc"
  auto_create_subnetworks = false
}

# GCP HA VPN Gateway
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway

resource "google_compute_ha_vpn_gateway" "gcp-to-aws-vpn-gw" {
  name    = "gcp-to-aws-vpn-gw"
  region  = var.region
  network = google_compute_network.main-vpc.id
}

# GCP External VPN Gateway
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_external_vpn_gateway

resource "google_compute_external_vpn_gateway" "gcp-to-aws-vpn-gw" {
  name            = "gcp-to-aws-vpn-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.aws-to-gcp-vpn1.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.aws-to-gcp-vpn1.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.aws-to-gcp-vpn2.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.aws-to-gcp-vpn2.tunnel2_address
  }
}

# GCP Cloud Router
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router

resource "google_compute_router" "gcp-to-aws-cloud-router" {
  name    = "gcp-to-aws-cloud-router"
  region  = var.region
  network = google_compute_network.main-vpc.id

  bgp {
    asn               = 65515
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.240.0.0/16"
    }
  }
}

# GCP VPN Tunnels
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel

# Tunnel 0
resource "google_compute_vpn_tunnel" "tunnel0" {
  name                            = "tunnel0"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp-to-aws-vpn-gw.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp-to-aws-vpn-gw.id
  peer_external_gateway_interface = 0
  shared_secret                   = "insert-pre-shared-key-1-here"       # Replace with your pre-shared key 1
  router                          = google_compute_router.gcp-to-aws-cloud-router.name
  ike_version                     = 2

}

# Tunnel 1
resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "tunnel1"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp-to-aws-vpn-gw.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp-to-aws-vpn-gw.id
  peer_external_gateway_interface = 1
  shared_secret                   = "insert-pre-shared-key-2-here"       # Replace with your pre-shared key 2
  router                          = google_compute_router.gcp-to-aws-cloud-router.name
  ike_version                     = 2
}

# Tunnel 2
resource "google_compute_vpn_tunnel" "tunnel2" {
  name                            = "tunnel2"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp-to-aws-vpn-gw.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp-to-aws-vpn-gw.id
  peer_external_gateway_interface = 2
  shared_secret                   = "insert-pre-shared-key-3-here"       # Replace with your pre-shared key 3
  router                          = google_compute_router.gcp-to-aws-cloud-router.name
  ike_version                     = 2
}

# Tunnel 3
resource "google_compute_vpn_tunnel" "tunnel3" {
  name                            = "tunnel3"
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp-to-aws-vpn-gw.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.gcp-to-aws-vpn-gw.id
  peer_external_gateway_interface = 3
  shared_secret                   = "insert-pre-shared-key-4-here"       # Replace with your pre-shared key 4
  router                          = google_compute_router.gcp-to-aws-cloud-router.name
  ike_version                     = 2
}

# GCP Router Interface and Peer Connection
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer

# Tunnel 0
resource "google_compute_router_interface" "gcp-router-interface-tunnel0" {
  name     = "gcp-router-interface-tunnel0"
  router   = google_compute_router.gcp-to-aws-cloud-router.name
  region   = var.region
  ip_range = "169.254.0.10/30"


  vpn_tunnel = google_compute_vpn_tunnel.tunnel0.name
}

resource "google_compute_router_peer" "gcp-router-peer-tunnel0" {
  name                      = "gcp-router-peer-tunnel0"
  router                    = google_compute_router.gcp-to-aws-cloud-router.name
  region                    = var.region
  peer_ip_address           = "169.254.0.9"
  peer_asn                  = 65501
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-router-interface-tunnel0.name
}

# Tunnel 1
resource "google_compute_router_interface" "gcp-router-interface-tunnel1" {
  name       = "gcp-router-interface-tunnel1"
  router     = google_compute_router.gcp-to-aws-cloud-router.name
  region     = var.region
  ip_range   = "169.254.0.14/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "gcp-router-peer-tunnel1" {
  name                      = "gcp-router-peer-tunnel1"
  router                    = google_compute_router.gcp-to-aws-cloud-router.name
  region                    = var.region
  peer_ip_address           = "169.254.0.13"
  peer_asn                  = 65501
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-router-interface-tunnel1.name
}

# Tunnel 2
resource "google_compute_router_interface" "gcp-router-interface-tunnel2" {
  name       = "gcp-router-interface-tunnel2"
  router     = google_compute_router.gcp-to-aws-cloud-router.name
  region     = var.region
  ip_range   = "169.254.0.18/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "gcp-router-peer-tunnel2" {
  name                      = "gcp-router-peer-tunnel2"
  router                    = google_compute_router.gcp-to-aws-cloud-router.name
  region                    = var.region
  peer_ip_address           = "169.254.0.17"
  peer_asn                  = 65501
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-router-interface-tunnel2.name
}

# Tunnel 3
resource "google_compute_router_interface" "gcp-router-interface-tunnel3" {
  name       = "gcp-router-interface-tunnel3"
  router     = google_compute_router.gcp-to-aws-cloud-router.name
  region     = var.region
  ip_range   = "169.254.0.22/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3.name
}

resource "google_compute_router_peer" "gcp-router-peer-tunnel3" {
  name                      = "gcp-router-peer-tunnel3"
  router                    = google_compute_router.gcp-to-aws-cloud-router.name
  region                    = var.region
  peer_ip_address           = "169.254.0.21"
  peer_asn                  = 65501
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp-router-interface-tunnel3.name
}

# GCP Firewall Rules
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall

# Allow IPSEC traffic
resource "google_compute_firewall" "allow_ipsec_from_aws" {
  name    = "allow-ipsec-from-aws"
  network = google_compute_network.main-vpc.name

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  source_ranges = [
    aws_vpn_connection.aws-to-gcp-vpn1.tunnel1_address,
    aws_vpn_connection.aws-to-gcp-vpn1.tunnel2_address,
    aws_vpn_connection.aws-to-gcp-vpn2.tunnel1_address,
    aws_vpn_connection.aws-to-gcp-vpn2.tunnel2_address
  ]

  direction   = "INGRESS"
  target_tags = ["vpn-access"]
  priority    = 1000
}

# Allow VPN traffic
resource "google_compute_firewall" "allow-vpn-traffic" {
  name    = "allow-vpn-traffic"
  network = google_compute_network.main-vpc.name

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "esp"
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  target_tags   = ["vpn-access"]
}
