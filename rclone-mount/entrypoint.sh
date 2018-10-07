#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=$UID_DIR

echo "Starting with UID : $USER_ID"
# useradd --shell /bin/bash -u $USER_ID -o -c "" -m user
# export HOME=/home/user

su-exec $UID_DIR:$UID_DIR "$@"
