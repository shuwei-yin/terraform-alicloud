variable "count" { default = "1" }
variable "count_format" {default = "%02d"}
variable "image_id" { default = "ubuntu1404_64_40G_cloudinit_20160727.raw" }

variable "role" {}
variable "datacenter" {}
variable "short_name" { default = "hi" }
variable "ec2_type" {}
variable "ec2_password" {}
variable "availability_zones" {}
variable "security_group_id" {}
variable "ssh_username" { default = "root" }

variable "internet_charge_type" {}
variable "internet_max_bandwidth_out" { default = 5 }

variable "disk_category" { default = "cloud_ssd" }
variable "disk_size" { default = "40" }
variable "device_name" { default = "/dev/xvdb" }

resource "alicloud_disk" "disk" {
  availability_zone = "${element(split(",", var.availability_zones), count.index)}"
  category = "${var.disk_category}"
  size = "${var.disk_size}"
  count = "${var.count}"
}

resource "alicloud_instance" "instance" {
  instance_name = "${var.short_name}-${var.role}-${format(var.count_format, count.index+1)}"
  host_name = "${var.short_name}-${var.role}-${format(var.count_format, count.index+1)}"
  image_id = "${var.image_id}"
  instance_type = "${var.ec2_type}"
  count = "${var.count}"
  availability_zone = "${element(split(",", var.availability_zones), count.index)}"
  security_group_id = "${var.security_group_id}"

  internet_charge_type = "${var.internet_charge_type}"
  internet_max_bandwidth_out = "${var.internet_max_bandwidth_out}"

  password = "${var.ec2_password}"

  instance_charge_type = "PostPaid"
  period = "1"
  system_disk_category = "cloud_efficiency"

  tags {
    sshUser = "${var.ssh_username}"
    role = "${var.role}"
    sshPrivateIp = "true"
    dc = "${var.datacenter}"
  }
}

resource "alicloud_allocate_pubic_ip" "allocate" {
  count = "${var.count}"
  instance_id = "${element(alicloud_instance.instance.*.id, count.index)}"

}

resource "alicloud_disk_attachment" "instance-attachment" {
  count = "${var.count}"
  disk_id = "${element(alicloud_disk.disk.*.id, count.index)}"
  instance_id = "${element(alicloud_instance.instance.*.id, count.index)}"
  device_name = "${var.device_name}"
}

output "hostname_list" {
  value = "${join(",", alicloud_instance.instance.*.instance_name)}"
}

output "public_ip" {
  value = "${alicloud_allocate_pubic_ip.allocate.id}"
}


output "ecs_ids" {
  value = "${join(",", alicloud_instance.instance.*.id)}"
}
