provider "google" {
  project     = "intrepid-axe-457404-n9"
  region      = var.region
  credentials = file("./config/terraform-svc-account.json")
}