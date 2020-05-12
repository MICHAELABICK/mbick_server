variable "gateway" {
  type = string
}

provider "proxmox" {
  pm_tls_insecure = true
}

module "docker-dev01" {
  source = "../modules/proxmox_cloud_init"

  name = "docker-dev01"
  node = "node1"
  clone = "ubuntu-bionic"

  cores = 2
  sockets = 1
  memory = 4096
  disk_gb = 20
  ip = "192.168.11.120/24"
  gateway = "${var.gateway}"

  groups = ["ubuntu_bionic", "docker_host"]
}