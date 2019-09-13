variable "gateway" {
  type = string
}

provider "proxmox" {
  pm_user = "terraform@pve"
  pm_password = "secret"
  pm_tls_insecure = true
}

module "cloudinit-test" {
  source = "../modules/proxmox_cloud_init"

  name = "cloudinit-test"
  node = "node1"
  clone = "packer-ubuntu-bionic"

  cores = 2
  sockets = 1
  memory = 4096
  disk_gb = 20
  ip = "192.168.11.121/24"
  gateway = "${var.gateway}"
}


# resource "proxmox_vm_qemu" "cloudinit-test" {
#   name = "cloudinit-test"
#   target_node = "node1"

#   clone = "packer-ubuntu-bionic"

#   cores       = 2
#   sockets     = 1
#   memory      = 2048

#   # ssh_user = "test"
#   # ssh_private_key = <<EOF
# # -----BEGIN RSA PRIVATE KEY-----
# # private ssh key root
# # -----END RSA PRIVATE KEY-----
# # EOF

#   disk {
#     id = 0
#     type = "scsi"
#     size = 4
#     storage = "local-zfs"
#   }
#   network {
#     id = 0
#     model = "virtio"
#     bridge = "vmbr0"
#   }

#   os_type = "cloud-init"
#   ipconfig0 = "ip=192.168.11.121/24,gw=${var.gateway}"

#   # ciuser = "test"
#   # cipassword = "test"

#   provisioner "remote-exec" {
#     inline = [
#       "ip a"
#     ]

#     connection {
#       type = "ssh"
#       user = "provision"
#       password = "provision"
#       host = "192.168.11.121"
#     }
#   }
# }
