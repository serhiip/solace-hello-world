# data "template_file" "solace_startup_stript" {
#   template = file("${path.module}/solace-broker-startup.sh")
# }

resource "google_compute_address" "solace_broker" {
  name = "solace-broker-ip-address"
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
    source_image      = "debian-cloud/debian-10"
    auto_delete       = true
    boot              = true
  }

  // Use an existing disk resource
  disk {
    // Instance Templates reference disks by name, not self link
    source      = google_compute_disk.foobar.name
    auto_delete = false
    boot        = false
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
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    docker-compose \
    git \
    -y
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y --allow-unauthenticated

#git clone https://github.com/SolaceLabs/solace-single-docker-compose.git
#cd solace-single-docker-compose/template
#sudo docker-compose -f PubSubStandard_singleNode.yml up -d
sudo docker run -d -p 8080:8080 -p 55555:55555 -p:8008:8008 -p:1883:1883 -p:8000:8000 -p:5672:5672 -p:9000:9000 -p:2222:2222 --shm-size=2g --env username_admin_globalaccesslevel=admin --env username_admin_password=admin --name=solace-broker solace/solace-pubsub-standard

EOF
}

data "google_compute_image" "my_image" {
  family  = "cos-stable"
  project = "cos-cloud"
}

resource "google_compute_disk" "foobar" {
  name  = "existing-disk"
  image = data.google_compute_image.my_image.self_link
  size  = 10
  type  = "pd-ssd"
  zone  = var.default_zone
}

resource "google_compute_instance_from_template" "solace_broker" {
  name = "solace-broker"
  zone = var.default_zone

  source_instance_template = google_compute_instance_template.solace_broker.id

  can_ip_forward = false
}
