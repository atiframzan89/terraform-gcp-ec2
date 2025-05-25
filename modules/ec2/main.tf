# Data

data "template_file" "startup-script" {
   template = file("${path.module}/templates/startup.sh")
#   vars = {
#     address = "some value"
#   }
}


# Reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance

resource "google_compute_instance" "public-ec2" {
  name         = "${var.customer}-public-ec2"
  machine_type = var.instance-size
  # zone         = "us-central1-a"
  zone         = var.zone.names[0] 
  allow_stopping_for_update = true

  tags = ["${var.customer}-ssh-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.instance-disk
    #   labels = {
    #     my_label = "value"
    #   }
    }
  }
  network_interface {
    network     = var.vpc-id
    subnetwork  = var.public-subnet
    access_config {
      network_tier = "STANDARD"

    }
  }
  metadata = {
    ssh-keys = "${var.ssh-username}:${var.ssh-public-key}"
  }
#   metadata_startup_script = file("${path.module}/templates/startup.sh")   
    metadata_startup_script = data.template_file.startup-script.rendered
}

resource "google_compute_instance" "private-ec2" {
  name         = "${var.customer}-private-ec2"
  machine_type = var.instance-size
  # zone         = "us-central1-a"
  zone         = var.zone.names[0]
  allow_stopping_for_update = true

  tags = ["${var.customer}-ssh-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.instance-disk
    #   labels = {
    #     my_label = "value"
    #   }
    }
  }
  network_interface {
    network     = var.vpc-id
    subnetwork  = var.private-subnet
    # network_ip = 
    # access_config {
    #   network_tier = "STANDARD"

    # }
  }
  metadata = {
    ssh-keys = "${var.ssh-username}:${var.ssh-public-key}"
  }
  metadata_startup_script = data.template_file.startup-script.rendered
}


# Application Load Balancer
# https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts#
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule

resource "google_compute_region_health_check" "alb-health-check" {
  name               = "${var.customer}-alb-health-check"
  region             = var.region
  http_health_check {
    port        = 80
    request_path = "/"
  }
}

resource "google_compute_region_backend_service" "alb-backend-service" {
  name                  = "${var.customer}-alb-backend-service"
  # region                = "us-central1"
  protocol              = "HTTP"
  health_checks         = [google_compute_region_health_check.alb-health-check.self_link]
  load_balancing_scheme = "EXTERNAL_MANAGED" # Key for regional ALB

  backend {
    group = google_compute_instance_group.alb-instance-group.self_link
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_url_map" "alb-url-map" {
  name            = "${var.customer}-alb"
  default_service = google_compute_region_backend_service.alb-backend-service.self_link
  region          = var.region
  depends_on = [ google_compute_region_backend_service.alb-backend-service ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_target_http_proxy" "alb-target-http-proxy" {
  name    = "${var.customer}-alb-target-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.alb-url-map.self_link
  depends_on = [ google_compute_region_url_map.alb-url-map, google_compute_subnetwork.proxy-only ]
}
# resource "google_compute_target_http_proxy" "alb-target-http-proxy" {
#   name    = "${var.customer}-target-http-proxy"
#   url_map = google_compute_url_map.alb-url-map.id
#   depends_on = [ google_compute_url_map.alb-url-map ]
# }

resource "google_compute_address" "alb-ip" {
  name         = "${var.customer}-alb-ip"
  region       = var.region
  network_tier = "STANDARD"
  # address_type = "INTERNAL" # For regional ALB, typically internal
  # subnet       = var.public-subnet # Replace with your subnet
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_forwarding_rule" "alb_forwarding_rule" {
  name                  = "${var.customer}-alb-forwarding-rule"
  region                = var.region
  load_balancing_scheme = "EXTERNAL_MANAGED" # Must match backend service
  # ip_protocol           = "HTTP"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.alb-target-http-proxy.id
  ip_address            = google_compute_address.alb-ip.address
  network               = var.vpc-id
  # subnetwork            = var.public-subnet # Required for internal IPs
  network_tier          = "STANDARD"
  depends_on            = [ google_compute_region_target_http_proxy.alb-target-http-proxy ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group" "alb-instance-group" {
  name    = "${var.customer}-instance-group"
  zone    = var.zone.names[0] # Ensure your instances are in this zone/region
  instances = [google_compute_instance.private-ec2.self_link] # Replace with your instance(s)
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_subnetwork" "proxy-only" {
  name          = "${var.customer}-proxy-subnet"
  ip_cidr_range = "10.0.5.0/24"
  region        = var.region
  network       = var.vpc-id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# resource "google_compute_subnetwork" "default" { # Replace with your actual subnet
#   name   = "default" # Or your specific subnet name
#   region = "us-central1"
#   network = var.vpc-id
# }

# Firewall Rule
# Reference https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.customer}-ssh-access"
  network = var.vpc-id 

  allow {
    protocol = "tcp"
    ports    = ["22","80"]
  }

  target_tags = ["${var.customer}-ssh-access"]
  source_ranges = ["0.0.0.0/0"]
#   project = "your-gcp-project-id" 
}