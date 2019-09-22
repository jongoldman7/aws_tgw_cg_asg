
resource "aws_vpc_peering_connection" "management_to_outbound_vpc_peering_connection" {
  peer_vpc_id   = "${data.aws_vpc.data_outbound_asg_vpc.id}"
  vpc_id        = "${aws_vpc.management_vpc.id}"
  auto_accept   = true

  tags {
    Name = "${var.project_name}-Management-to-Outbound-Peering"
  }
}

resource "aws_vpc_peering_connection" "management_to_inbound_vpc_peering_connection" {
    peer_vpc_id = "${aws_vpc.inbound_vpc.id}"
    vpc_id      = "${aws_vpc.management_vpc.id}"
    auto_accept = true

    tags {
        Name = "${var.project_name}-Management-to-Inbound-Peering"
    }
}
