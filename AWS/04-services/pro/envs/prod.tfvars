environment = "prod"

domain_name_lite = "lite.eco"

log_retention_in_days = 365

fargate_cpu    = 4096
fargate_memory = 8192

github_claim_suffixes = ["environment:prod"]

pro_stop_non_business_hours = false
pro_desired_tasks_count     = 1

pro_min_capacity = 0
pro_max_capacity = 0

backend_url_name = "app-pro-aws"