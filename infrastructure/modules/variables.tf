variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances"
  type        = string
}

variable "docker_image_server" {
  description = "Docker image for the Rust server"
  type        = string
}

variable "docker_image_client" {
  description = "Docker image for the Rust client"
  type        = string
}
