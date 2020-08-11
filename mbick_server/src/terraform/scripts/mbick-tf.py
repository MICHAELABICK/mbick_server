#!/usr/bin/env python3

import os
from tempfile import TemporaryDirectory
from glob import glob
import subprocess
import sys
from shutil import copytree


def main():
    cwd = os.getcwd()
    # init_dir = "{}/.terraform".format(cwd)

    src_dir = os.path.dirname(cwd)
    build_dir_base = os.path.join("build",os.path.basename(cwd))
    build_dir = os.path.join(src_dir,build_dir_base)
    tmp_dir = build_dir

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

    # symlink .terraform directory if it exists
    # if os.path.isdir(init_dir):
    #     src = init_dir
    #     dest = os.path.join(tmp_dir, ".terraform")
    #     os.symlink(src, dest)
    #     print("Symlinked {} to {}".format(src, dest))

    # generate terraform command arguments
    tf_cmd = sys.argv[1]
    tf_args = []
    if tf_cmd in ["plan", "apply", "destroy"]:
        tf_args.append("-state={}/terraform.tfstate".format(cwd))

    # run terraform command
    # os.chdir(tmp_dir)
    cmd = ["terraform", tf_cmd] + tf_args + sys.argv[2:] + [build_dir]
    print(subprocess.list2cmdline(cmd))
    subprocess.call(cmd)

    # # copy .terraform directory if it does not exist
    # if not os.path.isdir(init_dir):
    #     os.mkdir(init_dir)
    #     src = os.path.join(tmp_dir, ".terraform")
    #     dest = init_dir
    #     copytree(src, dest)
    #     print("Copied contents of {} to {}".format(src, dest))


if __name__ == "__main__":
    main()
