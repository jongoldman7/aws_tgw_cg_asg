data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#############################################
########### Spoke-1 Web Server  ##############
#############################################

locals {
  website = <<WEBSITE
sudo echo "" > index.html
sudo echo "Greetings!" >> index.html
sudo echo "----------" >> index.html
sudo echo "" >> index.html
sudo echo "This is a Spoke-1 web server!" >> index.html
sudo echo "" >> index.html
sudo nohup busybox httpd -f -p 80 &
sudo sleep 5
WEBSITE
}

resource "aws_instance" "spoke_1_instance" {
  ami                         = "${data.aws_ami.ubuntu_ami.id}"
  instance_type               = "t2.nano"
  count                       = "${length(data.aws_availability_zones.azs.names)}"
  availability_zone           = "${element(data.aws_availability_zones.azs.names, count.index)}"
  subnet_id                   = "${element(aws_subnet.spoke_1_external_subnet.*.id,count.index)}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = "false"
  vpc_security_group_ids      = ["${aws_security_group.spoke_1_security_group.id}"]

    user_data = <<-EOF
              #!/bin/bash
              echo "${local.website}" >> website.sh
              chmod +x website.sh
              mv ./website.sh /home/ubuntu/
              sudo echo "" > index.html
              sudo echo "Greetings!" >> index.html
              sudo echo "----------" >> index.html
              sudo echo "" >> index.html
              sudo echo "This is a web server in ${element(data.aws_availability_zones.azs.names, count.index)}!" >> index.html
              sudo echo "" >> index.html
              sudo nohup busybox httpd -f -p 80 &
              sudo sleep 5
              EOF

  tags {
    Name        = "${var.project_name}-Spoke-1 Web Server ${count.index+1}"
    Server      = "${var.project_name}-Website"
  }
}

######################################
########### Spoke-2 client ###########
######################################

resource "aws_instance" "spoke_2_instance" {
  ami                         = "${data.aws_ami.ubuntu_ami.id}"
  instance_type               = "t2.nano"
  subnet_id                   = "${aws_subnet.spoke_2_external_subnet.id}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = "false"
  vpc_security_group_ids      = ["${aws_security_group.spoke_2_security_group.id}"]
			  
  tags {
    Name    = "${var.project_name}-Spoke-2 Linux"
    Dev-Test    = "false"
    Prod-Test   = "true"
  }
}
 /*
output "test-Linux_IP" {
  value = "${aws_instance.spoke_2_instance.private_ip}"
} */