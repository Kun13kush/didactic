module "platform" {
  public_subnet_ids = module.networking.public_subnet_ids
  domain_name       = var.domain_name
  source            = "../../modules/platform"

  name               = "finzla-dev"
  environment        = "dev"
  log_retention_days = 7
  desired_count      = 1

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  image_digest = var.image_digest
  app_version  = var.app_version

  depends_on = [module.networking]
}

output "ecr_repository_url" {
  value = module.platform.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.platform.ecs_cluster_name
}

output "application_log_group" {
  value = module.platform.application_log_group
}

output "ecs_service_name" {
  value = module.platform.ecs_service_name
}

output "ecs_security_group_id" {
  value = module.platform.ecs_security_group_id
}
