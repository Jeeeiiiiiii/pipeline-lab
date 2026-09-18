variable "region" {
  type    = string
  default = "us-east-1"
}

variable "endpoint_url" {
  description = "Floci endpoint. Everything in providers.tf points here."
  type        = string
  default     = "http://localhost:4566"
}

variable "name" {
  description = "Prefix for every resource name and the EKS cluster name."
  type        = string
  default     = "pipeline-lab"
}

variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

# Two AZs: EKS wants its control plane ENIs spread across at least two.
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.0.0/24", "10.2.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.10.0/24", "10.2.11.0/24"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}
