resource "yandex_compute_snapshot_schedule" "default" {
  name           = "my-name"

  schedule_policy {
	expression = "0 0 * * *"
  }

  snapshot_count = 7
  retention_period = "24h"

  snapshot_spec {
	  description = "snapshot-description"
	  labels = {
	    snapshot-label = "my-snapshot-label-value"
	  }
  }

  labels = {
    my-label = "my-label-value"
  }

  disk_ids = [yandex_compute_instance.HOST-1.boot_disk.0.disk_id,
              yandex_compute_instance.HOST-2.boot_disk.0.disk_id,
              yandex_compute_instance.HOST-3.boot_disk.0.disk_id,
              yandex_compute_instance.HOST-4.boot_disk.0.disk_id,
              yandex_compute_instance.HOST-5.boot_disk.0.disk_id,
              yandex_compute_instance.HOST-6.boot_disk.0.disk_id]
}
