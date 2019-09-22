############################################
########### Management VPC  ################
############################################

# Create Outbound route tables
resource "aws_route_table" "Management_route_table" {
  vpc_id     = "${aws_vpc.management_vpc.id}"

  # Route to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.management_internet_gateway.id}"
  }

  # Route to the Outbound VPC via peering
  route {
    cidr_block                = "${var.outbound_cidr_vpc}"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.management_to_outbound_vpc_peering_connection.id}"
  }

  # Route to the Inbound VPC via peering
  route {
    cidr_block                = "${var.inbound_cidr_vpc}"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.management_to_inbound_vpc_peering_connection.id}"
  }

  tags {
    Name = "${var.project_name}-Management-External-Route"
  }
}

resource "aws_route_table_association" "management_table_association" {
  subnet_id      = "${aws_subnet.management_subnet.id}"
  route_table_id = "${aws_route_table.Management_route_table.id}"
}

##########################################
########### Inbound VPC  #################
##########################################

# Create Inbound route tables
resource "aws_route_table" "inbound_route_table" {
  vpc_id     = "${aws_vpc.inbound_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.inbound_internet_gateway.id}"
  }

  # Routes to Spokes
  route {
    cidr_block         = "${var.spoke_1_cidr_vpc}"
    transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  }

  route {
    cidr_block         = "${var.spoke_2_cidr_vpc}"
    transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  }
  
  # Route to the Management VPC via peering
  route {
    cidr_block                = "${var.management_cidr_vpc}"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.management_to_inbound_vpc_peering_connection.id}"
  }


  tags {
    Name = "${var.project_name}-Inbound-Route-Table"
  }
}

resource "aws_route_table_association" "inbound_table_association" {
  count          = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = "${element(aws_subnet.inbound_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.inbound_route_table.id}"
}

##########################################
########### Outbound VPC  ################
##########################################

data "aws_route_table" "data_outbound_asg_route_table" {
  filter {
    name   = "tag:aws:cloudformation:stack-name"
    values = ["CP-TGW-Gateway-TGW-VPCStack-*"]
  }

  depends_on = ["aws_cloudformation_stack.checkpoint_tgw_cloudformation_stack"]
}

# Route to the Management VPC
resource "aws_route" "outbound_to_management_route" {
  route_table_id            = "${data.aws_route_table.data_outbound_asg_route_table.id}"
  destination_cidr_block    = "${var.management_cidr_vpc}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.management_to_outbound_vpc_peering_connection.id}"
}


######################################
########### Spoke-1 VPC  #############
######################################

# Create a route table
resource "aws_route_table" "spoke_1_route_table" {
  vpc_id     = "${aws_vpc.spoke_1_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  }

  tags {
    Name = "${var.project_name}-Spoke-1-Route"
  }
}

resource "aws_route_table_association" "spoke-1_route_table_association" {
  count          = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = "${element(aws_subnet.spoke_1_external_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.spoke_1_route_table.id}"
}

######################################
########### Spoke-2 VPC  #############
######################################

# Create/Update routes
resource "aws_route_table" "spoke_2_route_table" {
  vpc_id     = "${aws_vpc.spoke_2_vpc.id}"

  route {
    cidr_block          = "0.0.0.0/0"
	  transit_gateway_id  = "${aws_ec2_transit_gateway.transit_gateway.id}"
  }

  tags {
    Name = "${var.project_name}-Spoke-2-Route"
  }
}

resource "aws_route_table_association" "spoke_2_route_table_association" {
  count          = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = "${aws_subnet.spoke_2_external_subnet.id}"
  route_table_id = "${aws_route_table.spoke_2_route_table.id}"
}


###########################################################
######## Transit GW - Outbound Spokes Route Table #########
###########################################################
# Create an outbound route table for the spokes VPCs
resource "aws_ec2_transit_gateway_route_table" "outbound_spoke_transit_gateway_route_table" {
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  tags {
    Name        = "${var.project_name}-TransitGW-Outbound-Spoke-Route-Table"
    x-chkp-vpn  = "${var.project_name}-Management/tgw-community/propagate"
  }
}

# Create route association
resource "aws_ec2_transit_gateway_route_table_association" "spoke_2_transit_gateway_route_table_association" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.spoke_2_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.outbound_spoke_transit_gateway_route_table.id}"
} 

###########################################################
######## Transit GW - Inbound Spokes Route Table #########
###########################################################
# Create an inbound route table for the spokes VPCs
# This is for spokes that need BOTH inbound and outbound connectivity
resource "aws_ec2_transit_gateway_route_table" "inbound_spoke_transit_gateway_route_table" {
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  tags {
    Name        = "${var.project_name}-TransitGW-Inbound-Spoke-Route-Table"
    x-chkp-vpn  = "${var.project_name}-Management/tgw-community/propagate"
  }
}

# Create route association
resource "aws_ec2_transit_gateway_route_table_association" "spoke_1_transit_gateway_route_table_association" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.spoke_1_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.inbound_spoke_transit_gateway_route_table.id}"
} 

# Create route propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "inbound_checkpoint_transit_gateway_route_table_propagation" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.inbound_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.inbound_spoke_transit_gateway_route_table.id}"
}


#######################################################
##### Transit GW - Outbound Security Route Table #######
#######################################################
# Create a route table for the Outbound Check Point VPC
resource "aws_ec2_transit_gateway_route_table" "checkpoint_outbound_transit_gateway_route_table" {
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  tags {
    Name        = "${var.project_name}-TransitGW-Outbound-CheckPoint-Route-Table"
    x-chkp-vpn  = "${var.project_name}-Management/tgw-community/associate"
  }
}

# Create route propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1_outbound_transit_gateway_route_table_propagation" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.spoke_1_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.checkpoint_outbound_transit_gateway_route_table.id}"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_2_outbound_transit_gateway_route_table_propagation" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.spoke_2_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.checkpoint_outbound_transit_gateway_route_table.id}"
}
##################################################################
##### Transit GW - Inbound Security Route Table #######
##################################################################
# Create a route table for the Inbound Check Point VPC 
resource "aws_ec2_transit_gateway_route_table" "checkpoint_inbound_transit_gateway_route_table" {
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  tags {
    Name        = "${var.project_name}-TransitGW-Inbound-CheckPoint-Route-Table"
  }
}

# Create route association
resource "aws_ec2_transit_gateway_route_table_association" "checkpoint_inbound_transit_gateway_route_table_association" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.inbound_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.checkpoint_inbound_transit_gateway_route_table.id}"
} 

# Create route propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1_inbound_transit_gateway_route_table_propagation" {
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.spoke_1_transit_gateway_vpc_attachment.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.checkpoint_inbound_transit_gateway_route_table.id}"
}
