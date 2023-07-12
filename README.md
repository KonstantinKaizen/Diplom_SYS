



Terraform apply ---> весь код в файлах main.tf,network.tf.
Также через terraform создаются все vpc, security groups,
alb.

![alt text](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/hosts.png)

Захожу на машину ansible через Putty, устанавливаю все пакеты на машины используя playbooks.
Все playbooks лежат в папке ansible.
Ниже скриншоты всей инфраструктуры

![alt text](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/alb+nginx site.png)

![alt text](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/GRAFANA.png)

![alt text](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/kibana.png)

![alt text](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/prometheus.png)


Скриншоты снапшотов + ежедневное копирование с жизнью снапшотов в неделю.

![alt text](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/snap.png)



![image alt](https://github.com/KonstantinKaizen/Diplom_SYS/blob/main/png/snap-daily.png)


Grafana - http://51.250.33.39:3000/   admin/admin
Kibana  - http://51.250.42.205:5601/
Prometheus - http://51.250.42.24:9090/
ALB - 51.250.9.28
elasticsearch - http://51.250.32.53:9200/

