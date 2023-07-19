#----------------- inventory.ini -----------------
resource "local_file" "ansible-inventory" {
  content  = <<-EOT
[all]
web1 ansible_ssh_host=${yandex_compute_instance.HOST-1.network_interface.0.ip_address} ansible_user=admin
web2 ansible_ssh_host=${yandex_compute_instance.HOST-2.network_interface.0.ip_address} ansible_user=admin
prometheus1 ansible_ssh_host=${yandex_compute_instance.HOST-3.network_interface.0.ip_address} ansible_user=admin
elastic1 ansible_ssh_host=${yandex_compute_instance.HOST-5.network_interface.0.ip_address} ansible_user=admin
[web]
web1 ansible_ssh_host=${yandex_compute_instance.HOST-1.network_interface.0.ip_address} ansible_user=admin
web2 ansible_ssh_host=${yandex_compute_instance.HOST-2.network_interface.0.ip_address} ansible_user=admin
[prometheus]
prometheus1 ansible_ssh_host=${yandex_compute_instance.HOST-3.network_interface.0.ip_address} ansible_user=admin
[grafana]
grafana1 ansible_ssh_host=${yandex_compute_instance.HOST-4.network_interface.0.ip_address} ansible_user=admin
[elastic]
elastic1 ansible_ssh_host=${yandex_compute_instance.HOST-5.network_interface.0.ip_address} ansible_user=admin
[kibana]
kibana1 ansible_ssh_host=${yandex_compute_instance.HOST-6.network_interface.0.ip_address} ansible_user=admin

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -p 22 -W %h:%p -q admin@${yandex_compute_instance.HOST-7.network_interface.0.nat_ip_address}"'

    EOT
  filename = "/etc/diplom/Diplom_SYS/ansible/inventory.ini"
}
