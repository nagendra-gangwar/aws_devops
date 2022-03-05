
data "aws_availability_zones" "available" {}


resource "aws_vpc" "AWSVPC" {
  cidr_block = var.main_vpc_cidr
  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-pvc"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-vpc"
  })

}

resource "aws_internet_gateway" "IGW" {
  
  vpc_id = aws_vpc.AWSVPC.id

  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-igw"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-igw"
  })
}

resource "aws_subnet" "public_subnet" {
  count = 2
  vpc_id = "${aws_vpc.AWSVPC.id}"
  cidr_block = format(var.public_subnets,"${var.start_public_subnets_zones+count.index}") # preparing address based on variables
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-public-subnet_${count.index}"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-public-subnet_${count.index}"
  })

}

resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = "${aws_vpc.AWSVPC.id}"
  cidr_block = format(var.private_subnets,"${var.start_private_subnets_zones+count.index}") # preparing address based on variables
  availability_zone= "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  
  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-private-subnet_${count.index}"}))}"

  tags_all = merge({
    "Name" = "${local.appname}-private-subnet_${count.index}"
  })
}

resource "aws_eip" "nateIP" {
   vpc   = true

   tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-elastic-ip"}))}"
  
   tags_all = merge({
      "Name" = "${local.appname}-elastic-ip"
   })
 }

 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.public_subnet[0].id # creating nat gateway in single availibility zone.

   tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-net-gateway"}))}"
  
   tags_all = merge({
      "Name" = "${local.appname}-net-gateway"
   })
 }

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.AWSVPC.id

  route {  
  cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
  gateway_id = aws_internet_gateway.IGW.id
  }
  
  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-public-route_table"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-public-route_table"
  })
}

resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.AWSVPC.id
  
 route {
  cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
  nat_gateway_id = aws_nat_gateway.NATgw.id
  }
  
  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-private-route_table"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-private-route_table"
  })
}


#Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation" {
   count = 2
   subnet_id = aws_subnet.public_subnet[count.index].id
   route_table_id = aws_route_table.PublicRT.id
 }
 #Route table Association with Private Subnet's
 resource "aws_route_table_association" "PrivateRTassociation" {
    count = 2
    subnet_id = aws_subnet.private_subnet[count.index].id
    route_table_id = aws_route_table.PrivateRT.id

 }