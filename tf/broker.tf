# data "template_file" "solace_startup_stript" {
#   template = file("${path.module}/solace-broker-startup.sh")
# }

resource "google_compute_address" "solace_broker" {
  name   = "solace-broker-ip-address"
  region = var.region
}

resource "google_compute_instance_template" "solace_broker" {
  name        = "solace-broker"
  description = "Solace broker template."

  tags = ["foo", "bar"]

  labels = {
    environment = "dev"
  }

  instance_description = "solace queue broker"
  machine_type         = "n1-standard-2"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip       = google_compute_address.solace_broker.address
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
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    git \
    python3 \
    python3-pip \
    -y

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y --allow-unauthenticated

sudo docker run -d -p 8080:8080 -p 55555:55555 -p:8008:8008 -p:1883:1883 -p:8000:8000 -p:5672:5672 -p:9000:9000 -p:2222:2222 --shm-size=2g --env username_admin_globalaccesslevel=admin --env username_admin_password=admin --name=solace-broker solace/solace-pubsub-standard

EOF
}

resource "google_compute_instance_from_template" "solace_broker" {
  name = "solace-broker"
  zone = var.default_zone

  source_instance_template = google_compute_instance_template.solace_broker.id

  can_ip_forward = false
}

output "broker-internal-ip" {
  value = google_compute_instance_from_template.solace_broker.network_interface[0].network_ip
}
