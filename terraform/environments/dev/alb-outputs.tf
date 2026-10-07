output "alb_dns_name" {
  value = module.platform.alb_dns_name
}

output "target_group_arn" {
  value = module.platform.target_group_arn
}

output "application_url" {
  value = module.platform.application_url
}
