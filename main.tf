resource "aws_instance" "tf-instance" {
  ami = var.ami
  key_name = var.key
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  instance_type = var.type
  tags = {
    Name = "Project-4-Server"
    Environment = "Production"
  }
}

resource "aws_security_group" "tf-sg" {
  name = "project-4-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks =["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks =["0.0.0.0/0"]
 }
 tags = {
    Name = "Project-4-SG"
    Environment = "Production"
  }
}
 resource "aws_s3_bucket" "tf-bucket" {
  bucket = "project-4-drift-adesh-2026"

  tags = {
    Name        = "Project-4-Bucket"
    Environment = "Production"
  }
}