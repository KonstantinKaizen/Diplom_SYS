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
  service_account_key_file = "C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\authorized_key.json"
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

resource "yandex_vpc_security_group" "group-ssh" {
  name        = "ssh"
  network_id  = yandex_vpc_network.default.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ICMP"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "group-web" {
  name        = "web"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 4040
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "group-prometheus" {
  name        = "prometheus"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
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

resource "yandex_vpc_security_group" "group-elasticsearch" {
  name        = "elasticsearch"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    port           = 9200
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


resource "yandex_vpc_security_group" "group-alb" {
  name        = "ALB"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

 egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

################################################################### Сеть и ее подсети #################################
resource "yandex_vpc_network" "default" {
  name = "ya-network"
}

resource "yandex_vpc_subnet" "ru-central1-a" {
  network_id     = yandex_vpc_network.default.id
  name           = "subnet-a"
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = "ru-central1-a"
}

resource "yandex_vpc_subnet" "ru-central1-b" {
  network_id     = yandex_vpc_network.default.id
  name           = "subnet-b"
  v4_cidr_blocks = ["192.168.2.0/24"]
  zone           = "ru-central1-b"
}

resource "yandex_vpc_subnet" "ru-central1-c" {
  name           = "subnet-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.3.0/24"]
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
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-web.id,yandex_vpc_security_group.group-ssh.id]
  }

  metadata = {
    user-data = "${file("C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\cloud-init.yaml")}"

    
  
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}



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
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-web.id,yandex_vpc_security_group.group-ssh.id]
  }

  metadata = {
    user-data = "${file("C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\cloud-init.yaml")}"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}


#

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
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-prometheus.id,yandex_vpc_security_group.group-ssh.id]
  }

  metadata = {
    user-data = "${file("C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\cloud-init.yaml")}"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}


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
    subnet_id = yandex_vpc_subnet.ru-central1-c.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-grafana.id,yandex_vpc_security_group.group-ssh.id]
  }

  metadata = {
    user-data = "${file("C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\cloud-init.yaml")}"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}


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
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-elasticsearch.id,yandex_vpc_security_group.group-ssh.id]
  }

  metadata = {
    user-data = "${file("C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\cloud-init.yaml")}"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}


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
    subnet_id = yandex_vpc_subnet.ru-central1-c.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.group-kibana.id,yandex_vpc_security_group.group-ssh.id]
  }

  metadata = {
    user-data = "${file("C:\\Users\\CHYEAH\\Desktop\\TERRAFORM\\cloud-init.yaml")}"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}



