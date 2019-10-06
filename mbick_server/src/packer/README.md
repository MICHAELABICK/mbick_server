# Production
To build production templates, like Proxmox, run

```sh
    PACKER_EXTRA_ARGS='-except=virtualbox-iso' make images
```

# Development
It can be useful to debug packer runs after failure.
To do this, use the command,

```sh
    PACKER_EXTRA_ARGS='-on-error=ask -except=virtualbox-iso' make images
```

Alternatively, packer can be run with virtualbox.
To do this, build the images using the command,

```sh
    PACKER_EXTRA_ARGS='-on-error=ask -only=virtualbox-iso' make images
```

# Validation
You may want to validate the Packer templates
before attempting to bake them.
This is done by running,

```sh
    make validate
```
