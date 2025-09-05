environment = "integ"

domain_name_lite = "lite-integ.net"

log_retention_in_days = 7

fargate_cpu    = 256
fargate_memory = 1024

github_claim_suffixes = ["environment:integ"]

pro_stop_non_business_hours = true
pro_desired_tasks_count     = 1

pro_min_capacity = 1
pro_max_capacity = 1
