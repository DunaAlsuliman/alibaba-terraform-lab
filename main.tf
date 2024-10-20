provider "alicloud" {

    access_key= var.access_key
    secret_key= var.secret_key
    region = "me-central-1"

}


resource "alicloud_vpc" "project_vpc" {
  cidr_block  = "10.0.0.0/8"
  vpc_name    = "tf-project"
}

data "alicloud_zones" "project_available_zones" {
  available_resource_creation = "VSwitch"
}
# vswitches
resource "alicloud_vswitch" "public" {
  vpc_id     = alicloud_vpc.project_vpc.id
  cidr_block = "10.0.1.0/24"
  zone_id    = data.alicloud_zones.project_available_zones.zones.0.id
  vswitch_name = "public"
}

resource "alicloud_vswitch" "private" {
  vpc_id     = alicloud_vpc.project_vpc.id
  cidr_block = "10.0.2.0/24"
  zone_id    = data.alicloud_zones.project_available_zones.zones.0.id
  vswitch_name = "private"
}


resource "alicloud_security_group" "app-security-group" {
  name        = "app-security-group"
  description = "security group for public instance"
  vpc_id      = alicloud_vpc.project_vpc.id
}


resource "alicloud_security_group_rule" "http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.app-security-group.id 
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.app-security-group.id 
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_key_pair" "key" {
  key_pair_name = "project-key"
  key_file    = "project-key.pem"
}

resource "alicloud_instance" "public" {

  availability_zone = data.alicloud_zones.project_available_zones.zones.0.id
  security_groups   = [alicloud_security_group.app-security-group.id]

  instance_type              = "ecs.g6.large"
  system_disk_category       = "cloud_essd"
  system_disk_size           = 40
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
  instance_name              = "public-instance"
  vswitch_id                 = alicloud_vswitch.public.id
  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByTraffic"
  instance_charge_type       = "PostPaid"
  key_name = alicloud_key_pair.key.key_pair_name

  user_data = base64encode(file("startup.sh"))
  }



  output "http_private_ip" {
  value = alicloud_instance.public.public_ip
  }
