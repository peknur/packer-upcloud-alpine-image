variable "upcloud_username" {
  description = "UpCloud API username"
  type        = string
  default     = env("UPCLOUD_API_USER")
}

variable "upcloud_password" {
  description = "UpCloud API password"
  type        = string
  default     = env("UPCLOUD_API_PASSWORD")
  sensitive   = true
}

variable "upcloud_zones" {
  description = "UpCloud availability zones"
  type        = list(string)
  default     = ["pl-waw1"]
}

variable "alpine_version" {
  type    = string
  default = "3.15"
}

variable "alpine_patch_version" {
  type    = string
  default = "4"
}

variable "root_password" {
  type      = string
  default   = "alpineR00T!"
  sensitive = true
}

variable "ssh_public_key_file" {
  description = "Path to file containing SSH public keys. Contents of this file will be written to /root/.ssh/authorized_keys file."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

locals {
  # remove dot from name 
  template_name = "alpine-${replace(var.alpine_version, ".", "-")}-amd64"
}

source "qemu" "alpine" {
  iso_url          = "https://dl-cdn.alpinelinux.org/alpine/v${var.alpine_version}/releases/x86_64/alpine-virt-${var.alpine_version}.${var.alpine_patch_version}-x86_64.iso"
  iso_checksum     = "file:https://dl-cdn.alpinelinux.org/alpine/v${var.alpine_version}/releases/x86_64/alpine-virt-${var.alpine_version}.${var.alpine_patch_version}-x86_64.iso.sha256"
  shutdown_command = "poweroff"
  disk_size        = "500M"
  memory           = 2048
  format           = "raw"
  headless         = true
  accelerator      = "kvm"
  ssh_username     = "root"
  ssh_password     = "${var.root_password}"
  ssh_timeout      = "2m"
  output_directory = "output"
  vm_name          = "${local.template_name}.raw"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  boot_wait        = "5s"
  # https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts
  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers.cfg<enter><wait>",
    "setup-alpine -f answers.cfg<enter><wait>",
    "${var.root_password}<enter><wait>",
    "${var.root_password}<enter><wait>",
    "<wait>y<enter><wait10>",
    "rc-service sshd stop<enter>",
    "mount /dev/vda3 /mnt<enter>",
    "echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter>",
    "umount /mnt<enter>",
    "reboot<enter>"

  ]
  http_content = {
    "/answers.cfg" = templatefile("answers.cfg", {
      "user" : {
      }
    })
  }

}

build {
  sources = ["source.qemu.alpine"]

  provisioner "file" {
    destination = "/etc/cloud"
    source      = "./provisioner.d/etc/cloud"
  }

  provisioner "shell" {
    script = "provisioner.sh"
  }

  provisioner "file" {
    destination = "/root/.ssh/authorized_keys"
    source      = pathexpand(var.ssh_public_key_file)
  }

  post-processors {
    post-processor "compress" {
      output = "alpine-${var.alpine_version}-x86_64.raw.gz"
    }
    post-processor "upcloud-import" {
      template_name    = "${local.template_name}"
      replace_existing = true
      username         = "${var.upcloud_username}"
      password         = "${var.upcloud_password}"
      zones            = var.upcloud_zones
    }
  }
}
