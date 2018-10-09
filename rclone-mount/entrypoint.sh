#!/bin/bash

PUID=${PUID:-9001}
PGID=${PGID:-9001}

addgroup -g $PGID -S abc
adduser -u $PUID -G abc -S abc

echo "Starting with UID : $PUID"
echo "Starting with GID : $PGID"

mkdir -p \
  /config
# rclone mkdir $RCLONE_REMOTE_MOUNT

chown -R abc:abc \
  /config
  # /data
# chmod 775 \
  # /config
  # /data
ls -la /data

exec su-exec abc:abc "$@"
