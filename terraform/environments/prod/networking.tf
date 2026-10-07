module "networking" {
  source = "../../modules/networking"

  name               = "finzla-prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-west-2a", "eu-west-2b"]
  nat_gateway_count  = 2
}

output "networking" {
  value = {
    vpc_id                  = module.networking.vpc_id
    public_subnet_ids       = module.networking.public_subnet_ids
    private_subnet_ids      = module.networking.private_subnet_ids
    public_route_table_id   = module.networking.public_route_table_id
    private_route_table_ids = module.networking.private_route_table_ids
    nat_gateway_ids         = module.networking.nat_gateway_ids
  }
}
