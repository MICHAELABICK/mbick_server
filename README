TODO: Add documentation about Ansible tags - http://www.inanzzz.com/index.php/post/wfj9/running-ansible-provisioning-by-passing-arguments-in-vagrant

# Installation

## Ansible
Ansible is a dependency used to provision various servers and images. I
recommend installing it with `pip` instead of `homebrew`, because some scripts
are dependent on the Ansible Python package. They will have issues finding it if Ansible is buried in Homebrew's cellar,

```sh
    pip install --user ansible
```

# Volume Types
* bind: bind mounted to any directory on the host
* mount-dir: bind mounted to the directory definied by `mount_dir`
* local: creates a named volume with the local driver
* rclone: creates a container that fuse mounts to a named directory, using rclone-mount
