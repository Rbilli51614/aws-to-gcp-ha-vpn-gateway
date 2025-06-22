# AWS Network Infrastructure
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc

resource "aws_vpc" "main-vpc" {
  cidr_block           = "10.230.0.0/16"            # Choose your CIDR block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# AWS VPN Setup = Virtual Private Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway

resource "aws_vpn_gateway" "aws-to-gcp-vpgw" {
  vpc_id          = aws_vpc.main-vpc.id
  amazon_side_asn = 65501

  tags = {
    Name = "aws-to-gcp-vpn-gw"
  }
}

# AWS VPN Setup = Customer Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway
# https://developer.hashicorp.com/terraform/language/expressions/for

# Customer Gateway 1
resource "aws_customer_gateway" "aws-to-gcp-cgw1" {
  bgp_asn = 65515
  ip_address = [
    for iface in google_compute_ha_vpn_gateway.gcp-to-aws-vpn-gw.vpn_interfaces :
    iface.ip_address if iface.id == 0
  ][0]
  type = "ipsec.1"

  tags = {
    Name = "aws-to-gcp-cgw1"
  }
}

# Customer Gateway 2
resource "aws_customer_gateway" "aws-to-gcp-cgw2" {
  bgp_asn = 65515
  ip_address = [
    for iface in google_compute_ha_vpn_gateway.gcp-to-aws-vpn-gw.vpn_interfaces :
    iface.ip_address if iface.id == 1
  ][0]
  type = "ipsec.1"

  tags = {
    Name = "aws-to-gcp-cgw2"
  }
}

# AWS VPN Setup = VPN Connections
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection

# VPN Connection 1
resource "aws_vpn_connection" "aws-to-gcp-vpn1" {
  vpn_gateway_id      = aws_vpn_gateway.aws-to-gcp-vpgw.id
  customer_gateway_id = aws_customer_gateway.aws-to-gcp-cgw1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr                  = "169.254.0.8/30"
  tunnel1_preshared_key                = "insert-pre-shared-key-1-here"       # Replace with your pre-shared key 1
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [15]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [15]

  tunnel2_inside_cidr                  = "169.254.0.12/30"
  tunnel2_preshared_key                = "insert-pre-shared-key-2-here"       # Replace with your pre-shared key 2
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [16]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [16]

  tags = {
    Name = "aws-to-gcp-vpn1"
  }
}

# VPN Connection 2
resource "aws_vpn_connection" "aws-to-gcp-vpn2" {
  vpn_gateway_id      = aws_vpn_gateway.aws-to-gcp-vpgw.id
  customer_gateway_id = aws_customer_gateway.aws-to-gcp-cgw2.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr                  = "169.254.0.16/30"
  tunnel1_preshared_key                = "insert-pre-shared-key-3-here"       # Replace with your pre-shared key 3
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [18]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [18]

  tunnel2_inside_cidr                  = "169.254.0.20/30"
  tunnel2_preshared_key                = "insert-pre-shared-key-4-here"       # Replace with your pre-shared key 4
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [19]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [19]

  tags = {
    Name = "aws-to-gcp-vpn2"
  }
}

# AWS VPN Setup = VPN Gateway Attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_attachment 

resource "aws_vpn_gateway_attachment" "aws-to-gcp-vpn-gw-attachment" {
  vpc_id         = aws_vpc.main-vpc.id
  vpn_gateway_id = aws_vpn_gateway.aws-to-gcp-vpgw.id
}
