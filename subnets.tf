##########################################
########### Management VPC  ##############
##########################################

# Create subnets to launch our instances into
resource "aws_subnet" "management_subnet" {
  vpc_id            = "${aws_vpc.management_vpc.id}"
  cidr_block        = "${cidrsubnet(var.management_cidr_vpc, 8, 1 )}"
  
  tags {
    Name = "${var.project_name}-Management"
  }
}

##########################################
########### Inbound VPC  ##############
##########################################

# Create subnets to launch our instances into
resource "aws_subnet" "inbound_subnet" {
  count             = "${length(data.aws_availability_zones.azs.names)}"
  availability_zone = "${element(data.aws_availability_zones.azs.names, count.index)}"
  vpc_id            = "${aws_vpc.inbound_vpc.id}"
  cidr_block        = "${cidrsubnet(var.inbound_cidr_vpc, 8, count.index+100 )}"
  
  tags {
    Name = "${var.project_name}-Inbound-${count.index+1}"
  }
}

#####################################
########### Spoke-1 VPC  ############
#####################################

# Create a subnet to launch our instances into
resource "aws_subnet" "spoke_1_external_subnet" {
  count             = "${length(data.aws_availability_zones.azs.names)}"
  availability_zone = "${element(data.aws_availability_zones.azs.names, count.index)}"
  vpc_id            = "${aws_vpc.spoke_1_vpc.id}"
  cidr_block        = "${cidrsubnet(var.spoke_1_cidr_vpc, 8, count.index+100 )}"
  
  tags {
    Name = "${var.project_name}-Spoke-1-External-${count.index+1}"
  }
}

######################################
########### Spoke-2 VPC  #############
######################################

# Create a subnet to launch our instances into
resource "aws_subnet" "spoke_2_external_subnet" {
  vpc_id     = "${aws_vpc.spoke_2_vpc.id}"
  cidr_block = "${var.spoke_2_cidr_vpc}"
  
  tags {
    Name = "${var.project_name}-Spoke-2-External"
  }
}