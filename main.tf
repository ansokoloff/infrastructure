provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

terraform {
  required_version = ">= v1.1.8"
  backend "gcs" {
    bucket = "testbucketepam"
    prefix  = "terraform/state"
  }
}


provider "tls" {
  // no config needed
}

resource "google_compute_firewall" "default" {
    name    = "final-task"
    network = "default"

    allow {
        protocol        = "tcp"
        ports           = var.firewall
    }

    source_ranges   = ["0.0.0.0/0"]

}

resource "tls_private_key" "key_deploy" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}

resource "local_file" "cloud_pem" {
    depends_on = [ tls_private_key.key_deploy ]
    filename = "cloud.pem"
    content = tls_private_key.key_deploy.private_key_pem
  }

resource "google_compute_instance" "app" {
    name            = "dev"
    machine_type = var.machine_type
    zone         = var.zone
    depends_on = [ tls_private_key.key_deploy,
      local_file.cloud_pem
  ]
  boot_disk {
    auto_delete = true
    initialize_params {
      image  = var.image
      labels = {}
      size   = 30
      type   = "pd-standard"
        }    
  }

  network_interface {
    network = "default"
    access_config {
            # Ephemeral
    }
  }

  metadata = {
    ssh-keys = "arctic:${tls_private_key.key_deploy.public_key_openssh}"
  }

}

resource "google_compute_instance" "kuber" {
    name            = "kuber"
    machine_type = var.machine_type
    zone         = var.zone
    depends_on = [ tls_private_key.key_deploy,
      local_file.cloud_pem
  ]
  boot_disk {
    auto_delete = true
    initialize_params {
      image  = var.image
      labels = {}
      size   = 30
      type   = "pd-standard"
        }    
  }

  network_interface {
    network = "default"
    access_config {
            # Ephemeral
    }
  }

  metadata = {
    ssh-keys = "arctic:${tls_private_key.key_deploy.public_key_openssh}"
  }

}

resource "google_compute_instance" "control" {
    name            = "master"
    machine_type = var.machine_type
    zone         = var.zone
    
    depends_on = [ tls_private_key.key_deploy,
      local_file.cloud_pem,
      google_compute_instance.app,
      google_compute_instance.kuber
    ]

  boot_disk {
    auto_delete = true
    initialize_params {
      image  = var.image
      labels = {}
      size   = 30
      type   = "pd-standard"
        }    
  }

  network_interface {
    network = "default"
    access_config {
            # Ephemeral
    }
  }

  metadata = {
    ssh-keys = "arctic:${tls_private_key.key_deploy.public_key_openssh}"
  }

  provisioner "file" { 
    source      = "cloud.pem"
    destination = ".ssh/id_rsa"
  }
 
  connection {
    user        = "arctic"
    private_key = "${tls_private_key.key_deploy.private_key_pem}"
    host        = "${google_compute_instance.control.network_interface.0.access_config.0.nat_ip}"
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo \"${tls_private_key.key_deploy.public_key_openssh}\" > .ssh/id_rsa.pub",
      "chmod -R 600 .ssh/*",
      "sudo apt update",
      "sudo apt -y install ansible", 
      "git clone https://github.com/ansokoloff/sprint1.git",
      "sudo cp sprint1/ansible.cfg /etc/ansible/ansible.cfg",
      "echo '[localhost]' >> hosts",
      "echo '127.0.0.1' >> hosts",
      "echo '[dev]' >> hosts",
      "echo ${google_compute_instance.app.network_interface.0.network_ip} >> hosts",
      "echo '[kuber]' >> hosts",
      "echo ${google_compute_instance.kuber.network_interface.0.network_ip} >> hosts",
      # "cd /home/arctic/sprint1 && ansible-playbook global.yaml"
    ]
  }  
}

output "control_ip_addr" {
  value = google_compute_instance.control.network_interface.0.access_config.0.nat_ip
}

output "app_ip_addr" {
  value = google_compute_instance.app.network_interface.0.network_ip
}

output "kuber_ip_addr" {
  value = google_compute_instance.kuber.network_interface.0.network_ip
}
