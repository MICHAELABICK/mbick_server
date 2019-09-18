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
  clone = "packer-ubuntu-bionic"

  cores = 2
  sockets = 1
  memory = 4096
  disk_gb = 20
  ip = "192.168.11.121/24"
  gateway = "${var.gateway}"

  groups = ["proxmox-vm", "ubuntu-bionic", "cloud-init", "docker-host"]
}
