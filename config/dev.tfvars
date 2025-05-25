region          = "us-central1"
customer        = "next"
ssh-username    = "atif_freelancing_work"
ssh-public-key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNGcIidKaAilL+PTn7P0VFjlkjBAh+/SNcF0uNej0v3kSfwWxDYVYZxfubgPFiQ5tJvPfdUxOOTxa6wQZI6rcXfgkhXnndgO499mhDqLNn6lu+wEP4iucP/+KgEpiECcFtEC0qZsO6pTkc7ZrgXxzxphLHeeHlJrE4XGCnqeh/dVEFMjB/SeGqCC/XwClLMf3HuBYK1f6jkIGLPcyuk5g0gpC9ayxeoRm/sOocWEiq59DTyhQmV5afhFwVSCZOdwqsRDWutIeyFMttsw+3NRd2TK0AcTVOA5XNaXJg92DNq/R/kUht4vj7fENGsik9B35UFhRjIF6fucyj109fs+O/"
vpc = {
    #name = "vpc"
    cidr                    = "10.0.0.0/16"
    public-subnet           = ["10.0.1.0/24", "10.0.2.0/24" ]
    private-subnet          = ["10.0.3.0/24", "10.0.4.0/24" ]
}
instance-size   = "e2-micro"
instance-disk   = "10"