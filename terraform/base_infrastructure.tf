resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "victim_bucket" {
  bucket = "soar-victim-bucket-${random_id.bucket_id.hex}"
}

resource "aws_iam_user" "victim_user" {
  name = "soar-victim-user"
  path = "/"
}

resource "aws_security_group" "victim_sg" {
  name        = "soar-victim-sg"
  description = "Baseline security group for SOAR testing"
  
  # Baseline rule: Only allow internal VPC traffic (Secure state)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] 
  }
}