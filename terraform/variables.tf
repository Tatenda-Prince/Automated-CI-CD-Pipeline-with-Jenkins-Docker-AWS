variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID"
  # You should replace this with the latest AMI for your region.
  default     = "ami-084568db4383264d4"
}

variable "key_name" {
  description = "The name of your existing EC2 Key Pair"
  type        = string
}
