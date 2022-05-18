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

## Debugging
Use `PACKER_LOG=1` environment variable to get more detailed logs. Check Packer's [debugging](https://www.packer.io/docs/debugging) documentation for more info.   
You can also set QEMU `headless` property to `false` to see what is happening during OS build process.