# Packer Alpine Image

Builds Alpine Linux using QEMU and imports image as private template (custom image) to UpCloud.

_Note that image has not been tested for production!_

## Usage
Check variable defauls from `alpine.pkr.hcl` and build using defaults:
```bash
$ make build
```
Use `packer` cli to overwrite default values. For example make template available in `fi-hel1` and `fi-hel2` zones:
```bash
$ packer build -var 'upcloud_zones=["fi-hel1", "fi-hel2"]' alpine.pkr.hcl
```
Using defaults requires that `UPCLOUD_API_PASSWORD` and `UPCLOUD_API_USER` are provided using environment variables.  
When deploying the server metadata service needs to enabled from UpCloud's control panel for image to work properly.  

_Note that in a absence of KVM acceleration you need to increase wait times (`boot_wait` and inside `boot_command`) heavily._
## Deployment example

Deploy image using Terraform and setup instance using `user_data`. This example assumes that template was created with name `alpine-3-15-amd64` and that it's available in `pl-waw1` zone.

`alpine.tf`
```terraform
terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~>2.0"
    }
  }
}

provider "upcloud" {}

data "upcloud_storage" "alpine_image" {
  type = "template"
  name = "alpine-3-15-amd64"
}

resource "upcloud_server" "alpine" {
  hostname = data.upcloud_storage.alpine_image.name
  zone     = "pl-waw1"
  metadata = true
  plan     = "1xCPU-1GB"

  network_interface {
    type = "public"
  }

  template {
    storage = data.upcloud_storage.alpine_image.id
    size    = 20
  }

  user_data = templatefile("alpine_user_data.sh", {}) 
}
```

`alpine_user_data.sh`
```sh
#!/bin/ash

apk -U upgrade
apk add nginx

# ... do more setup tasks at last stages in boot process. Network is available at this point.
```
## Debugging
Use `PACKER_LOG=1` environment variable to get more detailed logs. Check Packer's [debugging](https://www.packer.io/docs/debugging) documentation for more info.   
You can also set QEMU `headless` property to `false` to see what is happening during OS build process.