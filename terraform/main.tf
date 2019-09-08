provider "proxmox" {
  pm_user = "terraform@pve"
  pm_password = "secret"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "cloudinit-test" {
  name = "cloudinit-test"
  target_node = "node1"

  clone = "packer-ubuntu-bionic"

  cores       = 2
  sockets     = 1
  memory      = 2048
  disk_gb = 4
  nic = "virtio"
  bridge = "vmbr0"

  # ssh_user = "test"
  # ssh_private_key = <<EOF
# -----BEGIN RSA PRIVATE KEY-----
# private ssh key root
# -----END RSA PRIVATE KEY-----
# EOF

  os_type = "cloud-init"
  network {
    id = 0
    model = "virtio"
  }

  ciuser = "test"
  cipassword = "test"

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}
