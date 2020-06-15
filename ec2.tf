provider "aws" {
region   = "ap-south-1"
profile  = "firsttask"
}

resource "tls_private_key" "vpk" {
  algorithm = "RSA"
}
  
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "vp_key"
  public_key = tls_private_key.vpk.public_key_openssh
}

resource "aws_security_group" "request" {
  name        = "request"
  description = "Allow TCP inbound traffic"
  vpc_id      = "vpc-a3637fcb"

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "allow_http_request"
  }
}


resource "aws_instance" "vpos" {
  ami            =  "ami-0447a12f28fddb066"
  instance_type  =  "t2.micro"
  key_name       =  "vp_key"
  security_groups = ["request"]
    user_data = <<-EOF
    #! /bin/bash
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo yum install git -y
    mkfs.ext4 /dev/sdd
    mount /dev/sdd /var/www/html
    cd /var/www/html
    git clone https://github.com/vikaspandey96/vikascloud.git
    EOF

  tags = {
  Name = "myteraos"
  }
}

resource "aws_ebs_volume" "myebsvol1" {
  availability_zone = aws_instance.vpos.availability_zone
  size = 1

  tags = {
    Name = "myebsvol1"
  }
}


resource "aws_volume_attachment" "myebs_attach" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.myebsvol1.id 
  instance_id = aws_instance.vpos.id 
  force_detach = true

  }






resource "aws_s3_bucket" "vikasbuckt1" {
  bucket = "vikasbuckt1"
  acl    = "private"

  tags = {
    Name        = " vikasbuckt1"
    Environment = "Deploy"
  }
}


resource "aws_s3_bucket_object" "bukcetobject" {

  bucket = "vikasbuckt1"
  acl    = "public-read"
  key    = "demo.jpg"
  source = ("C:/Users/pandey/Desktop/demo.jpg")
 etag = filemd5("C:/Users/pandey/Desktop/demo.jpg")
  

}


resource "aws_cloudfront_distribution" "vikcloud" {
    origin {
        domain_name = "vikasbuckt1.s3.amazonaws.com"
        origin_id = "S3-vikasbuckt1"


    }
       
    enabled = true



    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-vikasbuckt1"

        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
 
    restrictions {
        geo_restriction {
       restriction_type = "blacklist"
        locations = ["US"]
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true

    }
}






      
  



      
  