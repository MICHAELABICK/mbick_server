variable "gateway" {
  type = string
}

provider "proxmox" {
  pm_tls_insecure = true
}

module "proxmox_cloud_init" {
  source = "../modules/proxmox_cloud_init"

  name = "docker-dev"
  node = "node1"
  clone = "packer-ubuntu-bionic"

  cores = 2
  sockets = 1
  memory = 4096
  disk_gb = 20
  ip = "192.168.11.121/24"
  gateway = "${var.gateway}"
}
