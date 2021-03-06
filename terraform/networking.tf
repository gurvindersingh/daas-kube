# Networks

resource "openstack_networking_network_v2" "network_1" {
  name = "${var.cluster_name}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name = "${var.cluster_name}_subnet"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr = "10.2.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_1" {
  name = "${var.cluster_name}_router"
  external_gateway = "${var.public_v4_network}"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}


# Security groups

resource "openstack_networking_secgroup_v2" "ssh_access" {
    region = "${var.region}"
    name = "ssh_access"
    description = "Security groups for allowing SSH access"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_access_ipv4" {
    count = "${length(var.allow_ssh_from_v4)}"
    region = "${var.region}"
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = 22
    port_range_max = 22
    remote_ip_prefix = "${element(var.allow_ssh_from_v4, count.index)}"
    security_group_id = "${openstack_networking_secgroup_v2.ssh_access.id}"
}

resource "openstack_networking_secgroup_v2" "kube_lb" {
    region = "${var.region}"
    name = "kube_lb"
    description = "Security groups for allowing access to lb nodes"
}

# Allows access to kubernetes node port range from load balancers
resource "openstack_networking_secgroup_rule_v2" "kube_lb_nodeport_ipv4" {
    count = "${length(var.allow_lb_from_v4)}"
    region = "${var.region}"
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = 30000
    port_range_max = 32767
    remote_ip_prefix = "${element(var.allow_lb_from_v4, count.index)}"
    security_group_id = "${openstack_networking_secgroup_v2.kube_lb.id}"
}

resource "openstack_networking_secgroup_v2" "kube_master" {
    region = "${var.region}"
    name = "kube_master"
    description = "Security groups for allowing API access to the master nodes"
}

resource "openstack_networking_secgroup_rule_v2" "kube_master_ipv4" {
    count = "${length(var.allow_api_access_from_v4)}"
    region = "${var.region}"
    direction = "ingress"
    ethertype = "IPv4"
    protocol = "tcp"
    port_range_min = 8443
    port_range_max = 8443
    remote_ip_prefix = "${element(var.allow_api_access_from_v4, count.index)}"
    security_group_id = "${openstack_networking_secgroup_v2.kube_master.id}"
}

