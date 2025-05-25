module "vpc" {
        source          = "./modules/vpc"
        customer        = var.customer
        region          = var.region
        vpc             = var.vpc

}

module "ec2" {
        source          = "./modules/ec2"
        region          = var.region 
        customer        = var.customer
        vpc-id          = module.vpc.vpc-id
        private-subnet  = module.vpc.private-subnet-cidr
        public-subnet   = module.vpc.public-subnet-cidr
        ssh-username    = var.ssh-username
        ssh-public-key  = var.ssh-public-key
        depends_on      = [ module.vpc ]
        zone            = data.google_compute_zones.available
        instance-size   = var.instance-size
        instance-disk   = var.instance-disk

}