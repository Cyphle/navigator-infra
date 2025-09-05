variable "pro_container_name" {
  description = "Name of the main container"
  type        = string
  default     = "pro"
}

variable "pro_port" {
  description = "Port the application pro will listen"
  type        = number
  default     = 8080
}

variable "pro_desired_tasks_count" {
  description = "Number of containers to execute in parallel"
  type        = number
}

variable "pro_health_check_path" {
  description = "URI used by ALB to check target health"
  type        = string
  default     = "/"
}

variable "pro_rule_priority" {
  description = "Rule priority for ALB listener"
  type        = number
  default     = 10
}


variable "pro_min_capacity" {
  description = "Minimum number of running tasks"
  type        = number
}

variable "pro_max_capacity" {
  description = "Maximum number of running tasks"
  type        = number
}

variable "pro_stop_non_business_hours" {
  description = "Stop resources during non business hours"
  type        = bool
  default     = false
}

variable "pro_start_time" {
  description = "Time to start service"
  type        = string
  default     = "cron(0 9 ? * MON-FRI *)"
}

variable "pro_stop_time" {
  description = "Time to stop service"
  type        = string
  default     = "cron(0 20 ? * MON-FRI *)"
}

variable "pro_timezone" {
  description = "Timezone to manage service"
  type        = string
  default     = "Europe/Paris"
}
