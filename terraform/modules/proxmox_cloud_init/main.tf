locals {
  provision_dir = "../../provisioning"
  ssh_dir = "../../ssh"

  ssh_host = "${element(split("/", var.ip), 0)}"
  description_map = {"groups" = concat(["proxmox_vm", "cloud_init", "terraform_managed"], var.groups)}

  default_user = "provision"
  # default_password = "provision"
  default_private_key_file = "${local.ssh_dir}/default"
  default_public_key_file = "${local.ssh_dir}/default.pub"
  default_public_key = "${chomp(file(local.default_public_key_file))}"
  ssh_user = "mbick"
}

resource "proxmox_vm_qemu" "proxmox_cloud_init" {
  name = "${var.name}"
  desc = "${jsonencode(local.description_map)}"
  target_node = "${var.node}"
  clone = "${var.clone}"

  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory

  # Activate QEMU agent for this VM
  agent = 1

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

  ciuser = local.default_user
  # cipassword = local.default_password
  sshkeys = <<EOF
${local.default_public_key}
EOF

  provisioner "local-exec" {
    command = "ssh-keygen -R ${local.ssh_host}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"Connection to ${local.ssh_host} established \""
    ]

    connection {
      type = "ssh"
      user = "${local.default_user}"
      # password = "${local.default_password}"
      private_key = "${file(local.default_private_key_file)}"
      host = "${local.ssh_host}"
    }
  }

  provisioner "local-exec" {
    # command = "ansible-inventory -i \"${local.provision_dir}/inventory\" --list"
    command = "ansible-playbook --limit \"${var.name}\" -u ${local.default_user} --private-key=${local.default_private_key_file} -i \"${local.provision_dir}/inventory\" \"${local.provision_dir}/manage_users.yml\""

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "false"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook --limit \"${var.name}\" -u ${local.ssh_user} -i \"${local.provision_dir}/inventory\" \"${local.provision_dir}/provision.yml\""
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "ssh-keygen -R ${local.ssh_host}"
  }
}
