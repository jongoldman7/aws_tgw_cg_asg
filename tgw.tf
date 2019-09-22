#####################################
######### Transit GW  ###############
#####################################

# Create the TGW
resource "aws_ec2_transit_gateway" "transit_gateway" {
  description = "${var.project_name}"
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags {
    Name        = "${var.project_name}"
    x-chkp-vpn  = "${var.management_server_name}/tgw-community"
  }
}

# Attach TGW to the Inbound VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "inbound_transit_gateway_vpc_attachment" {
  subnet_ids         = ["${aws_subnet.inbound_subnet.*.id}"]
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  vpc_id             = "${aws_vpc.inbound_vpc.id}"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags {
    Name = "${var.project_name}-Inbound-TGW-Attachment"
  }
} 

# Attach TGW to Spoke-1 VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1_transit_gateway_vpc_attachment" {
  subnet_ids         = ["${aws_subnet.spoke_1_external_subnet.*.id}"]
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  vpc_id             = "${aws_vpc.spoke_1_vpc.id}"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags {
    Name = "${var.project_name}-Spoke-1-TGW-Attachment"
  }
}

# Attach TGW to Spoek-2 VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2_transit_gateway_vpc_attachment" {
  subnet_ids         = ["${aws_subnet.spoke_2_external_subnet.id}"]
  transit_gateway_id = "${aws_ec2_transit_gateway.transit_gateway.id}"
  vpc_id             = "${aws_vpc.spoke_2_vpc.id}"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags {
    Name = "${var.project_name}-Spoke-2-TGW-Attachment"
  } 
}
