# Production
To build production templates, like Proxmox, run

```sh
    PACKER_EXTRA_ARGS='-except=virtualbox-iso' make images
```

# Development
It can be useful to develop packer images with virtualbox. To do this, build the images using the command

```sh
    PACKER_EXTRA_ARGS='-only=virtualbox-iso' make images
```
