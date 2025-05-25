# data "google_compute_zones" "available" {}

# output "zones" {
#   value = data.google_compute_zones.available.names[0]

# }

output "alb-ip-output" {
   value = module.ec2.alb-ip
}