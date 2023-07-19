terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

locals {
  folder_id = "b1gtnfglcemgv6rir8et"
  cloud_id  = "b1gj0rlfbh4r0ujld0vo"
}

provider "yandex" {
  cloud_id                 = "b1gj0rlfbh4r0ujld0vo"
  folder_id                = "b1gtnfglcemgv6rir8et"
  service_account_key_file = "/etc/diplom/Diplom_SYS/authorized_key.json"
}


data "yandex_compute_image" "debian-11" {
  family = "debian-11"
}

############################################################### Security group #################################


resource "yandex_vpc_security_group" "group-bastion" {
  name        = "bastion"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "private" {
  name        = "ssh"
  network_id  = yandex_vpc_network.default.id
  ingress {
    protocol       = "ANY"    
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "192.168.4.0/24"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "group-grafana" {
  name        = "grafana"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  
}


resource "yandex_vpc_security_group" "group-kibana" {
  name        = "kibana"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "public-load-balancer" {
  name       = "public-load-balancer-rules"
  network_id = yandex_vpc_network.default.id

  ingress {
    protocol          = "ANY"
    description       = "Health checks"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    description    = "allow HTTP connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}




################################################################### Сеть и ее подсети #################################
resource "yandex_vpc_network" "default" {
  name = "ya-network"
}

resource "yandex_vpc_route_table" "inner-to-nat" {
  network_id = yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
   # next_hop_address   = yandex_compute_instance.HOST-7.network_interface.0.ip_address
    gateway_id         = yandex_vpc_gateway.nat_gateway.id  
  }
}


resource "yandex_vpc_gateway" "nat_gateway" {
  name = "test-gateway"
  shared_egress_gateway {}
}



########### private VPC
resource "yandex_vpc_subnet" "ru-central1-a" {
  network_id     = yandex_vpc_network.default.id
  name           = "subnet-a"
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = "ru-central1-a"
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}

resource "yandex_vpc_subnet" "ru-central1-b" {
  network_id     = yandex_vpc_network.default.id
  name           = "subnet-b"
  v4_cidr_blocks = ["192.168.2.0/24"]
  zone           = "ru-central1-b"
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}

resource "yandex_vpc_subnet" "ru-central1-c" {
  name           = "subnet-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.3.0/24"]
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
  
}


############# public VPC


resource "yandex_vpc_subnet" "ru-central1-c-public" {
  name           = "subnet-c-public"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.4.0/24"]
}



#######################################################################################################################

data "template_file" "default" {
  template = file("${path.module}/init.ps1")
  vars = {
    user_name  = var.user_name
    user_pass  = var.user_pass
    admin_pass = var.admin_pass
  }
}




####################################HOSTS HOSTS HOSTS#################################################################
resource "yandex_compute_instance" "HOST-1" {
  name     = "web-1"
  hostname = "web-1"
  zone     = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-a.id
    #nat       = true
    security_group_ids = [yandex_vpc_security_group.private.id]
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"

    
  
  }

  scheduling_policy {
    preemptible = true
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

##

resource "yandex_compute_instance" "HOST-2" {
  name     = "web-2"
  hostname = "web-2"
  zone     = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-b.id
    #nat       = true
    security_group_ids = [yandex_vpc_security_group.private.id]
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }


  timeouts {
    create = "10m"
    delete = "10m"
  }
}


##

resource "yandex_compute_instance" "HOST-3" {
  name     = "prometheus"
  hostname = "prometheus"
  zone     = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-c.id
    #nat       = true
    security_group_ids = [yandex_vpc_security_group.private.id]
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"
  }
  
  scheduling_policy {
    preemptible = true
  }


  timeouts {
    create = "10m"
    delete = "10m"
  }
}

##


resource "yandex_compute_instance" "HOST-4" {
  name     = "grafana"
  hostname = "grafana"
  zone     = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-c-public.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-grafana.id,yandex_vpc_security_group.private.id]
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"
  }
  
  scheduling_policy {
    preemptible = true
  }


  timeouts {
    create = "10m"
    delete = "10m"
  }
}

##


resource "yandex_compute_instance" "HOST-5" {
  name     = "elasticsearch"
  hostname = "elasticsearch"
  zone     = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-c.id
    #nat       = true
    security_group_ids = [yandex_vpc_security_group.private.id]
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"
  }
  
  scheduling_policy {
    preemptible = true
  }


  timeouts {
    create = "10m"
    delete = "10m"
  }
}

##


resource "yandex_compute_instance" "HOST-6" {
  name     = "kibana"
  hostname = "kibana"
  zone     = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-c-public.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-kibana.id,yandex_vpc_security_group.private.id]
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"
  }
  
  scheduling_policy {
    preemptible = true
  }


  timeouts {
    create = "10m"
    delete = "10m"
  }
}


################### bastion########################
resource "yandex_compute_instance" "HOST-7" {
  name        = "bastion"
  hostname    = "bastion"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-11.id
      size     = 15
      type     = "network-nvme"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru-central1-c-public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.group-bastion.id]
   # ip_address         = "10.0.4.4"
  }

  metadata = {
    user-data = "${file("/etc/diplom/Diplom_SYS/cloud-init.yaml")}"
  }

  scheduling_policy {  
    preemptible = true
  }
}




