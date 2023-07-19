resource "yandex_alb_target_group" "target_group" {
  name = "target-group-1"

  target {
    ip_address = yandex_compute_instance.HOST-1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.ru-central1-a.id
  }

  target {
    ip_address = yandex_compute_instance.HOST-2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.ru-central1-b.id
  }
}





resource "yandex_alb_backend_group" "backend_group" {
  name = "backend-group"

  http_backend {
    name             = "backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.target_group.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}




resource "yandex_alb_http_router" "http_router" {
  name = "http-router"
}

resource "yandex_alb_virtual_host" "virtual_host" {
  name           = "virtual-host"
  http_router_id = yandex_alb_http_router.http_router.id
  route {
    name = "root-path"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend_group.id
        timeout          = "3s"
      }
    }
  }
}







resource "yandex_alb_load_balancer" "load_balancer" {
  name               = "load-balancer"
  network_id         = yandex_vpc_network.default.id
 # security_group_ids = [yandex_vpc_security_group.public-load-balancer.id,yandex_vpc_security_group.private.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-c"
      subnet_id = yandex_vpc_subnet.ru-central1-c.id
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http_router.id
      }
    }
  }
}
