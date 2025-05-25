resource "google_compute_network" "vpc-network" {
  name                      = "${var.customer}-vpc"
  auto_create_subnetworks   = false
  
}

# Reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "public-subnet" {
    for_each        = {
                    for idx, cidr in var.vpc.public-subnet : "public-subnet-${idx + 1}" => cidr
    }
    name            = "${var.customer}-${each.key}"
    region          = var.region
    network         = google_compute_network.vpc-network.id
    # ip_cidr_range   = "10.0.1.0/24"
    ip_cidr_range   = each.value
    lifecycle {
    create_before_destroy = true
  }
     
}

# Reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "private-subnet" {
    for_each        = {
                    for idx, cidr in var.vpc.private-subnet : "private-subnet-${idx + 1}" => cidr
    }
    name            = "${var.customer}-${each.key}"
    region          = var.region
    network         = google_compute_network.vpc-network.id
    # ip_cidr_range   = "10.0.2.0/24"
    ip_cidr_range   = each.value
    lifecycle {
    create_before_destroy = true
  }
}

# Reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "encrypted-interconnect-router" {
  name                          = "${var.customer}-router"
  network                       = google_compute_network.vpc-network.name
  encrypted_interconnect_router = true
#   bgp {
#     asn = 64514
#   }
}

# Reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat

resource "google_compute_router_nat" "nat-gateway" {
  # for_each        = {
  #                   for idx, cidr in var.vpc.private-subnet : "private-subnet-${idx + 1}" => cidr
  #   }
  name                               = "${var.customer}-nat-gw"
  router                             = google_compute_router.encrypted-interconnect-router.name
  region                             = google_compute_router.encrypted-interconnect-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  depends_on = [ google_compute_subnetwork.private-subnet ]
  dynamic "subnetwork" {
    for_each = {
      for idx, cidr in var.vpc.private-subnet :
      "private-subnet-${idx + 1}" => cidr
    }
    content {
      name                    = "${var.customer}-${subnetwork.key}"
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  
  # subnetwork {
  #   name                    = "${var.customer}-private-subnet-${each.key}"
  #   source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  # }

  lifecycle {
    create_before_destroy = true
  }
  

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}