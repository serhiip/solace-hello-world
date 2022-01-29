resource "google_compute_address" "solace_client" {
  name = "solace-client-ip-address"
  region = var.region
}

resource "google_compute_instance_template" "solace_client" {
  name        = "solace-client"
  description = "Solace client template."

  instance_description = "solace queue client"
  machine_type         = "e2-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image      = "debian-cloud/debian-10"
    auto_delete       = true
    boot              = true
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.solace_broker.address
      network_tier = "STANDARD"
    }
  }

  metadata = {
    foo = "bar"
  }

  # metadata_startup_script = data.template_file.solace_startup_stript.rendered
  metadata_startup_script = <<-EOF

sudo apt-get update
sudo apt-get install \
    python3 \
    python3-pip \
    -y

EOF
}

resource "google_compute_instance_from_template" "solace_client" {
  name = "solace-client"
  zone = var.default_zone

  source_instance_template = google_compute_instance_template.solace_client.id

  can_ip_forward = false
}
