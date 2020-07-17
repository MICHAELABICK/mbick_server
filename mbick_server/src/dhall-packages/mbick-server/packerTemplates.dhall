let Prelude = ./Prelude.dhall
let List/map = Prelude.List.map
let JSON = Prelude.JSON

let networking = ../networking/package.dhall

let lab_config = ./config.dhall
let util = ./util.dhall


let Builder = <
      | proxmox :
          {
          , proxmox_url :
              Text
          , insecure_skip_tls_verify :
              Bool
          , username :
              Text
          , password :
              Text
          , vm_name :
              Text
          , node :
              Text
          , sockets :
              Natural
          , cores :
              Natural
          , memory :
              Text
          , os :
              Text
          , network_adapters :
              List {
              , model :
                  Text
              , bridge :
                  Text
              }
          , disks :
              List {
              , type :
                  Text
              , disk_size :
                  Text
              , storage_pool :
                  Text
              , storage_pool_type :
                  Text
              , format :
                  Text
              }
          , qemu_agent :
              Bool
          , iso_file :
              Text
          , http_directory :
              Text
          , boot_wait :
              Text
          , boot_command :
              List Text
          , ssh_username :
              Text
          , ssh_password :
              Text
          , ssh_timeout :
              Text
          , unmount_iso :
              Bool
          , template_description :
              Text
          , cloud_init :
              Bool
          }
      | virtualbox-iso :
          {
          , output_directory :
              Text
          , memory :
              Natural
          , disk_size :
              Natural
          , guest_os_type :
              Text
          , iso_url :
              Text
          , iso_checksum :
              Text
          , iso_checksum_type :
              Text
          , http_directory :
              Text
          , boot_command :
              List Text
          , shutdown_command :
              Text
          , ssh_username :
              Text
          , ssh_password :
              Text
          }
      >


let ChecksumType = <
      | MD5
      >

let OSImage = {
      , iso_url : Text
      , checksum : Text
      , checksum_type : ChecksumType
      , proxmox_file : Text
      , virtualbox_guest_os_type : Text
      }

let VMTemplate = {
      , name : Text
      , description : Text
      , image : OSImage
      , http_directory : Text
      , boot_command_suffix : List Text
      , groups : List Text
      }

let ChildVMTemplate = {
      , name : Text
      , parent : VMTemplate
      , description : Text
      , groups : List Text
      }


let ssh_username = "packer"
let ssh_password = "packer"
let ssh_fullname = "packer"

let toPacker =
      \(template : VMTemplate)
  ->  let template_fullname = "${template.name}-{{timestamp}}"
      let memory_mb = 1024
      let disk_size_mb = 25000
      let boot_command = [
            , "<esc><esc><enter><wait>"
            , "/install/vmlinuz "
            , "preseed/url=http://{{user `local_host_ip`}}:{{ .HTTPPort }}/preseed.cfg "
            ]
            # template.boot_command_suffix
      in
      {
      , variables = {
          , proxmox_user =
              "{{ vault `/proxmox_user/data/packer` `username` }}"
          , proxmox_password =
              "{{ vault `/proxmox_user/data/packer` `password` }}"
          , hostname = template.name
          }
      , builders =
          List/map
          Builder
          (JSON.Tagged Builder)
          (\(x : Builder) -> JSON.tagInline "type" Builder x)
          [
          , Builder.proxmox {
            , proxmox_url =
                networking.HostURL.show lab_config.proxmox_api.address
            , insecure_skip_tls_verify = True
            , username = "{{user `proxmox_user`}}"
            , password = "{{user `proxmox_password`}}"
            , vm_name = template_fullname
            , node = "node1"
            , sockets = 1
            , cores = 2
            , memory = "${Natural/show memory_mb}"
            , os = "l26"
            , network_adapters = [
                , {
                  , model = "virtio"
                  , bridge = "vmbr0"
                  }
                ]
            , disks = [
                , {
                  , type = "scsi"
                  , disk_size = "${Natural/show disk_size_mb}M"
                  , storage_pool = "vm-images"
                  , storage_pool_type = "nfs"
                  , format = "qcow2"
                  }
                ]
            , qemu_agent = True
            , iso_file = template.image.proxmox_file
            , http_directory = template.http_directory
            , boot_wait = "10s"
            , boot_command = boot_command
            , ssh_username = ssh_username
            , ssh_password = ssh_password
            , ssh_timeout = "30m"
            , unmount_iso = True
            , template_description =
                "${template.description}, generated on {{ isotime \"2006-01-02T15:04:05Z\" }}"
            , cloud_init = True
            }
          , Builder.virtualbox-iso {
            , output_directory = "output-${template_fullname}-virtualbox-iso"
            , memory = memory_mb
            , disk_size = disk_size_mb
            , guest_os_type = template.image.virtualbox_guest_os_type
            , iso_url = template.image.iso_url
            , iso_checksum = template.image.checksum
            , iso_checksum_type =
                merge {
                , MD5 = "md5"
                }
                template.image.checksum_type
            , http_directory = template.http_directory
            , boot_command = boot_command
            , shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
            , ssh_username = ssh_username
            , ssh_password = ssh_password
            }
          ]
      , provisioners = [
        , {
          , type = "ansible"
          , pause_before = "5s"
          , playbook_file =
              util.renderAnsiblePlaybookPath lab_config "bake_image.yml"
          , extra_arguments = [
              , "-i"
              , "${util.renderAnsibleInventoryPath lab_config}/group_inventory"
              , "-e"
              , "ansible_become_password=${ssh_password}"
              ]
          , groups = [
              , "proxmox_vm"
              , "cloud_init"
              ]
              # template.groups
          , user = ssh_username
          }
        ]
      , post-processors = [
          , {
            , type = "vagrant"
            , keep_input_artifact = False
            , output = "box/{{.Provider}}/${template_fullname}.box"
            , only = [ "virtualbox-iso" ]
            }
          ]
      }

let toVMTemplate =
      \(child : ChildVMTemplate)
  ->  let parent = child.parent
      let template =
            parent // {
            , name = child.name
            , description = child.description
            , groups =
              parent.groups
              # child.groups
            }
      in template


let locale = "en_US"

let ubuntu_bionic = {
      , name = "ubuntu-bionic"
      , description = "Ubuntu 18.04.02"
      , image = {
          , iso_url =
              "http://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04.2-server-amd64.iso"
          , checksum =
              "34416ff83179728d54583bf3f18d42d2"
          , checksum_type =
              ChecksumType.MD5
          , proxmox_file =
              "vm-isos:iso/ubuntu-18.04.2-server-amd64.iso"
          , virtualbox_guest_os_type = "Ubuntu_64"
          }
      , http_directory =
          "{{template_dir}}/ubuntu_bionic/http"
      , boot_command_suffix = [
         , "auto "
         , "console-setup/ask_detect=false "
         , "debconf/frontend=noninteractive "
         , "debian-installer=${locale} "
         , "hostname={{ user `hostname` }} "
         , "fb=false "
         , "grub-installer/bootdev=/dev/sda<wait> "
         , "initrd=/install/initrd.gz "
         , "kbd-chooser/method=us "
         , "keyboard-configuration/modelcode=SKIP "
         , "keyboard-configuration/layout=USA "
         , "keyboard-configuration/variant=USA "
         , "locale=${locale} "
         , "noapic "
         , "passwd/user-fullname=${ssh_fullname} "
         , "passwd/user-password=${ssh_password} "
         , "passwd/user-password-again=${ssh_password} "
         , "passwd/username=${ssh_username} "
         , "-- <enter>"
         ]
      , groups = [ "ubuntu_bionic" ]
      }

let docker =
      toVMTemplate {
      , name = "docker"
      , parent = ubuntu_bionic
      , description = "Docker installed on ${ubuntu_bionic.description}"
      , groups = [ "docker_host" ]
      }


in {
, ubuntu_bionic = toPacker ubuntu_bionic
, docker = toPacker docker
}
