provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "mysub1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my sub1"
  }
}

resource "aws_subnet" "mysub2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "my sub2"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
resource "aws_route_table" "myrt1" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mysub1.id
  route_table_id = aws_route_table.myrt1.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.mysub2.id
  route_table_id = aws_route_table.myrt1.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.myrt1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from vpc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
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
    Name = "allow_ssh"
  }
}

resource "aws_instance" "ecc1" {
  ami                    = "ami-0ad21ae1d0696ad58"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mysub1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data              = base64encode(file("userdata.sh"))

  tags = {
    Name = "Chandu1"
  }

}
resource "aws_instance" "ecc2" {
  ami                    = "ami-0ad21ae1d0696ad58"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mysub2.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data              = base64encode(file("userdata1.sh"))

  tags = {
    Name = "Chandu2"
  }
}

output "instance_id_1" {
  value = aws_instance.ecc1.id
}

output "instance_id_2" {
  value = aws_instance.ecc2.id
}

resource "aws_s3_bucket" "mys3" {
  bucket = "my-tf-test-chandu12"

  tags = {
    Name        = "My bucket2305"
    Environment = "Dev"
  }
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.mysub1.id, aws_subnet.mysub2.id]
}
resource "aws_lb_target_group" "tg" {
  name     = "tf-example-lb-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "tg1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ecc1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ecc2.id
  port             = 80
}


resource "aws_lb_listener" "pt1" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "loadbalancerdns" {
  value = aws_lb.test.dns_name
}
