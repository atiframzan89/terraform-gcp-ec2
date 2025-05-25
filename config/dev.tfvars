region          = "us-central1"
customer        = "next"
ssh-username    = "atif_freelancing_work"
ssh-public-key  = "your-ssh-key"
vpc = {
    #name = "vpc"
    cidr                    = "10.0.0.0/16"
    public-subnet           = ["10.0.1.0/24", "10.0.2.0/24" ]
    private-subnet          = ["10.0.3.0/24", "10.0.4.0/24" ]
}
instance-size   = "e2-micro"
instance-disk   = "10"