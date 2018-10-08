FROM tynor88/rclone-mount:dev AS base

FROM base AS dev

FROM base AS prod
COPY ./config/rclone $CONFIG_DIR
