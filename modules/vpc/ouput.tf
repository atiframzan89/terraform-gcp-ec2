output "private-subnet-cidr" {
  value = google_compute_subnetwork.private-subnet["private-subnet-1"].id
}

output "public-subnet-cidr" {
  value = google_compute_subnetwork.public-subnet["public-subnet-1"].id
}

output "vpc-id" {
  value = google_compute_network.vpc-network.id
}