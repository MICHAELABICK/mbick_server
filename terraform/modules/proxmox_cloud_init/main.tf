locals {
  ssh_user = "provision"
  ssh_password = "provision"
  ssh_host = "${element(split("/", var.ip), 0)}"
}

resource "proxmox_vm_qemu" "cloudinit-test" {
  name = "${var.name}"
  target_node = "${var.node}"
  clone = "${var.clone}"

  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory

  disk {
    id = 0
    type = "scsi"
    size = var.disk_gb
    storage = "local-zfs"
  }
  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=${var.ip},gw=${var.gateway}"

  # ciuser = local.ssh_user
  # cipassword = local.ssh_password

  provisioner "remote-exec" {
    inline = [
      "echo \"Connection to ${local.ssh_host} established \""
    ]

    connection {
      type = "ssh"
      user = "${local.ssh_user}"
      password = "${local.ssh_password}"
      host = "${local.ssh_host}"
    }
  }

  # provisioner "local-exec" {
  #   command = "ansible-playbook -u ${local.ssh_user} ../../../provisioning/provision.yml"
  # }
}
