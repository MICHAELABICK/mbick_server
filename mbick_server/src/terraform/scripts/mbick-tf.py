#!/usr/bin/env python3

import os
from tempfile import TemporaryDirectory
from glob import glob
import subprocess
import sys
from shutil import copytree


def main():
    cwd = os.getcwd()
    src_dir = os.path.dirname(cwd)
    build_dir_base = os.path.join("build",os.path.basename(cwd))
    build_dir = os.path.join(src_dir,build_dir_base)

    # Show terraform CLI if no arguments are given
    if len(sys.argv) == 1:
        cmd = ["terraform", "-h"]
        print(subprocess.list2cmdline(cmd))
        subprocess.check_call(cmd)
        return

    # Make terraform config file
    cmd = ["make", "-C", src_dir, os.path.join(build_dir_base,"main.tf.json")]
    print(subprocess.list2cmdline(cmd))
    subprocess.check_call(cmd)

    # generate terraform command arguments
    tf_cmd = sys.argv[1]
    tf_args = []
    if tf_cmd in ["plan", "apply", "destroy"]:
        tf_args.append("-state={}".format(os.path.join(cwd,"terraform.tfstate")))

    # run terraform command
    cmd = ["terraform", tf_cmd] + tf_args + sys.argv[2:] + [build_dir]
    print(subprocess.list2cmdline(cmd))
    subprocess.call(cmd)


if __name__ == "__main__":
    main()
