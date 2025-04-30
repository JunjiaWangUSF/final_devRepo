variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile"
  default     = "default"
}

variable "project_name" {
  description = "EKS Cluster name"
  default     = "eks-blue-green"
}
