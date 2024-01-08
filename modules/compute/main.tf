variable "network_self_link" {}

resource "google_compute_instance" "temp-vm" {
  name = "temp-vm"
  machine_type = "f1-micro"
  zone = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = var.network_self_link
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install apache2 -y
    sudo service apache2 start
    echo "Hello from temporary instance!" | sudo tee /var/www/html/index.html
  EOF

  allow_stopping_for_update = true

}

resource "google_compute_snapshot" "vm_snapshot" {
  name = "temp-vm-snapshot"
  source_disk = google_compute_instance.temp-vm.boot_disk.0.source
  zone = var.zone
  depends_on = [ google_compute_instance.temp-vm ]
}


resource "google_compute_image" "vm_image" {
  name = "vm-iamge"
  source_snapshot = google_compute_snapshot.vm_snapshot.self_link
}

#Instance template for scale set
resource "google_compute_instance_template" "template" {
  name = "instance-template"
  machine_type = "f1-micro"

  disk {
    source_image = google_compute_image.vm_image.self_link
    auto_delete = true
    boot = true
  }
  
  network_interface {
    network = var.network_self_link
  }

}

#Group manager
resource "google_compute_instance_group_manager" "manager" {
  name = "instance-group-manager"
  base_instance_name = "instance"
  zone = var.zone
  target_size = 3

  version {
    instance_template = google_compute_instance_template.template.self_link
  }
}
