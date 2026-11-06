variable "aws_region" {
  description = "AWS region where the application will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix AWS resources."
  type        = string
  default     = "mango-list"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the application VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Two availability zones used for the VPC and RDS subnet group."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones are required."
  }
}

variable "allowed_app_cidr" {
  description = "CIDR allowed to reach the app directly on port 3000. Prefer a trusted IP or a load balancer security group."
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type for the application host."
  type        = string
  default     = "t3.micro"
}

variable "image_tag" {
  description = "Container tag to pull from ECR during instance bootstrap."
  type        = string
  default     = "latest"
}

variable "origin" {
  description = "Public origin used by SvelteKit and shown as app_url. Use the DuckDNS https URL or http://ELASTIC_IP:3000 — not an old ephemeral IP."
  type        = string
  default     = "http://localhost:3000"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
  default     = 20
}
