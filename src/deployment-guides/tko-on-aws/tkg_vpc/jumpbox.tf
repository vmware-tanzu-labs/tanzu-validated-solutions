
resource "aws_subnet" "jump-net" {
  count                   = var.jumpbox ? 1 : 0
  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.subnet_addrs.network_cidr_blocks.az3_jumpnet
  availability_zone       = var.azs[2]
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.gw]
  tags = {
    Name = "jb-net"
  }
}

resource "aws_route_table_association" "a" {
  count          = var.jumpbox ? 1 : 0
  subnet_id      = aws_subnet.jump-net[count.index].id
  route_table_id = aws_route_table.r.id
}
resource "aws_network_interface" "foo" {
  count     = var.jumpbox ? 1 : 0
  subnet_id = aws_subnet.jump-net[count.index].id
  tags = {
    Name = "jb-interface"
  }

}

resource "aws_eip" "bar" {
  count = var.jumpbox ? 1 : 0
  vpc   = true

  instance                  = aws_instance.ubuntu[count.index].id
  associate_with_private_ip = aws_network_interface.foo[count.index].private_ip
  depends_on                = [aws_internet_gateway.gw]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "ubuntu" {
  count                = var.jumpbox ? 1 : 0
  key_name             = var.jb_key_pair
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.medium"
  iam_instance_profile = "control-plane.tkg.cloud.vmware.com"
  lifecycle {
    ignore_changes = [ebs_block_device, tags]
  }
  tags = {
    Name = "ubuntu"
  }

  #vpc_security_group_ids = [
  #  aws_security_group.ubuntu.id
  #]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${var.jb_keyfile}")
    host        = self.public_ip
  }

  network_interface {
    network_interface_id = aws_network_interface.foo[count.index].id
    device_index         = 0
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 30
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /home/ubuntu/tkg-install",
    ]
  }
  provisioner "file" {
    source      = "./tkg_vpc/script.sh"
    destination = "/home/ubuntu/tkg-install/script.sh"
  }
  provisioner "file" {
    source      = "./tkg_vpc/config_files/"
    destination = "/home/ubuntu/tkg-install"
  }
  provisioner "file" {
    content = templatefile("./tkg_vpc/templates/mgmt.tpl",
      {
        region        = "us-west-2",
        priv_subnet_a = aws_subnet.priv_a.id,
        priv_subnet_b = aws_subnet.priv_b.id,
        priv_subnet_c = aws_subnet.priv_c.id
        pub_subnet_a  = aws_subnet.pub_a.id,
        pub_subnet_b  = aws_subnet.pub_b.id,
        pub_subnet_c  = aws_subnet.pub_c.id
        vpc_id        = aws_vpc.main.id
        az1           = var.azs[0],
        az2           = var.azs[1],
      az3 = var.azs[2] }
    )
    destination = "/home/ubuntu/tkg-install/mgmt.yaml"
  }

  provisioner "file" {
    content = templatefile("./tkg_vpc/templates/to-registration.tpl",
      {
        TO_URL = "${var.to_url}",
      TO_TOKEN = "${var.to_token}", }
    )
    destination = "/home/ubuntu/tkg-install/to-registration.yaml"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/tkg-install/script.sh",
      "/home/ubuntu/tkg-install/script.sh",
    ]
  }
  # Can't get this to work because we reference the ssh key using a variable..
  # provisioner "remote-exec" {
  #   when = destroy
  #   inline = [
  #     "chmod +x /home/ubuntu/tkg-install/clean-up.sh",
  #     "/home/ubuntu/tkg-install/clean-up.sh",
  #   ]
  # }
}
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  count                = var.jumpbox ? 1 : 0
  security_group_id    = aws_security_group.sg[count.index].id
  network_interface_id = aws_network_interface.foo[count.index].id
}

resource "aws_security_group" "sg" {
  count       = var.jumpbox ? 1 : 0
  name        = "ssh_in_all_out"
  description = "ssh in all out"
  vpc_id      = aws_vpc.main.id

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
    Name = "allow_tls"
  }
}

output "jumpbox_dns" {
  value = aws_eip.bar[*].public_ip
}
